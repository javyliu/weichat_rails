require "weichat_rails/api"
require  "weichat_rails/auto_generate_secret_key"

module WeichatRails

  autoload :Message, "weichat_rails/message"
  autoload :Responder, "weichat_rails/responder"

  class AccessTokenExpiredError < StandardError; end

  class ResponseError < StandardError
    attr_reader :error_code
    def initialize(errcode, errmsg)
      error_code = errcode
      super "#{errmsg}(#{error_code})"
    end
  end


  class << self
    def config
      @config || OpenStruct.new({wechat_secret_string: nil,wechat_token_string: nil})
    end

    #can configure the wechat_secret_string,wechat_token_string in weichat_rails_config.rb file
    def configure
      yield config if block_given?
    end

  end

  #DEFAULT_TOKEN_COLUMN_NAME = "wechat_token".freeze
  #DEFAULT_WECHAT_SECRET_KEY = "wechat_secret_key".freeze


  #def self.api
  # # @api ||= WechatRails::Api.new(self.config.appid, self.config.secret, self.config.access_token)
  #end
end

if defined? ActionController::Base
  class ActionController::Base
    def self.wechat_responder opts={}
      self.send(:include, WeichatRails::Responder)
    end
  end
end
