module WeichatRails
  class AccessToken
    attr_reader :client, :appid, :secret

    def initialize(client, appid, secret)
      @appid = appid
      @secret = secret
      @client = client
    end

    #store token in rails.cache
    def token
      Rails.cache.fetch("w_access_token#{appid}",expires_in: 7200) do
        data = client.get("token", params:{grant_type: "client_credential", appid: appid, secret: secret})
        valid_token(data)
      end
    end

    #delete the cache
    def refresh
      Rails.cache.delete("w_access_token#{appid}")
    end

    private
    def valid_token token_data
      access_token = token_data["access_token"]
      raise "Response didn't have access_token" if  access_token.blank?
      return access_token
    end

  end
end
