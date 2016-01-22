require 'http'
require 'tempfile'
require 'active_support/core_ext/object/blank'

module WeichatRails
  class Client

    attr_reader :base,:ssl_context

    def initialize(base, timeout, skip_verify_ssl)
      @base = base
      HTTP.timeout(:global, write: timeout, connect: timeout, read: timeout)
      @ssl_context = OpenSSL::SSL::SSLContext.new
      @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE if skip_verify_ssl
    end

    def get(path, get_header = {})
      request(path, get_header) do |url, header|
        params = header.delete(:params)
        HTTP.headers(header).get(url, params: params, ssl_context: ssl_context)
      end
    end

    def post(path, payload, post_header = {})
      request(path, post_header) do |url, header|
        params = header.delete(:params)
        HTTP.headers(header).post(url, params: params, body: payload, ssl_context: ssl_context)
      end
    end

    def post_file(path, file, post_header = {})
      request(path, post_header) do |url, header|
        params = header.delete(:params)
        HTTP.headers(header)
        .post(url, params: params,
              form: { media: HTTP::FormData::File.new(file),
                      hack: 'X' }, # Existing here for http-form_data 1.0.1 handle single param improperly
                      ssl_context: ssl_context)
      end
    end




    def request path, header={}, &block
      url = "#{header.delete(:base) || self.base}#{path}"
      as = header.delete(:as)
      header.merge!('Accept' => 'application/json')
      response = yield(url, header)

      raise "Request not OK, response status #{response.status}" if response.status != 200
      parse_response(response, as || :json) do |parse_as, data|
        break data unless (parse_as == :json && data["errcode"].present?)
        #break data if (parse_as != :json || data["errcode"].blank?)

        #如果返回的是json数据并且errcode有值，则会对errcode再做开关判断

        case data["errcode"]
        when 0 # for request didn't expect results
          [true,data]

        when 42001, 40014,40001,48001 #42001: access_token超时, 40014:不合法的access_token
          raise AccessTokenExpiredError
        else
          raise ResponseError.new(data['errcode'], data['errmsg'])
        end
      end
    end

    private
    def parse_response response, as
      content_type = response.headers[:content_type]
      parse_as = {
        /^application\/json/ => :json,
        /^image\/.*/ => :file
      }.inject([]){|memo, match| memo<<match[1] if content_type =~ match[0]; memo}.first || as || :text

      case parse_as
      when :file
        file = Tempfile.new("tmp")
        file.binmode
        file.write(response.body)
        file.close
        data = file

      when :json
        data = JSON.parse response.body.to_s.gsub(/[\u0000-\u001f]+/, '')

      else
        data = response.body
      end

      return yield(parse_as, data)
    end

  end
end

