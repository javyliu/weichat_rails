require "weichat_rails/api"
require  "weichat_rails/auto_generate_secret_key"
require 'dalli'

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

  Config = Struct.new(:cache,:cache_namespace,:appid,:secret,:timeout,:skip_verify_ssl)

  class << self

    def config
      @config ||= Config.new(nil,'weichat_rails',nil,nil,20,true)
    end

    def api
      @weichat_api ||= WeichatRails::Api.new(config.appid,config.secret,config.timeout,config.skip_verify_ssl)
    end



    #can configure the wechat_secret_string,wechat_token_string in weichat_rails_config.rb file
    def configure
      yield config if block_given?
    end

  end

  #config.cache_namespace = 'weichat_rails'

  #if use rails with dalli,you can set config.cache = Rails.cache
  self.config.cache ||= if defined?(::Rails)
                     Rails.cache
                   else
                     Dalli::Client.new('localhost:11211',namespace: config.cache_namespace,conpress: true)
                   end
end

if defined? ActionController::Base
  class ActionController::Base
    def self.wechat_responder opts={}
      self.send(:include, WeichatRails::Responder)
    end
  end
end
