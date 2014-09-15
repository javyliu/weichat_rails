module WeichatRails
  module Responder
    extend ActiveSupport::Concern

    included do
      self.skip_before_filter :verify_authenticity_token
      self.before_filter :verify_signature, only: [:show, :create]
      self.before_filter :init_wechat_or_token, only: [:show, :create]
      #delegate :wehcat, to: :class
    end

    attr_accessor :wechat, :token


    module ClassMethods

      #create rules
      #we can can store rules in database instead of use on method
      def on message_type, with: nil, respond: nil, &block
        raise "Unknow message type" unless message_type.in? [:text, :image, :voice, :video, :location, :link, :event, :fallback]
        config=respond.nil? ? {} : {:respond=>respond}
        config.merge!(:proc=>block) if block_given?

        if (with.present? && !message_type.in?([:text, :event]))
          raise "Only text and event message can take :with parameters"
        else
          config.merge!(:with=>with) if with.present?
        end

        responders(message_type) << config
        return config
      end

      def responders type
        @responders ||= Hash.new
        @responders[type] ||= Array.new
      end

      #用于处理用户请求，该方法只关注用户信息类型及用户请求的内容或事件信息
      #事件类型：subscribe(订阅)、unsubscribe(取消订阅),SCAN(关注后扫描)，LOCATION（上报地理位置）,CLICK(自定义菜单事件),VIEW(点击菜单跳转链接时的事件推送)
      def responder_for message, &block
        message_type = message[:MsgType].to_sym
        responders = responders(message_type)

        case message_type
        when :text
          yield(* match_responders(responders, message[:Content]))

        when :event
          yield(* match_responders(responders, message[:Event]))

        else
          yield(responders.first)
        end
      end

      private

      #该方法用于确定预先用on定义的返回信息(一个数组 [{with:,proc:,respond:},*args])做循环处理
      #responds : 预先定义的某类返回信息,类型为[:text, :image, :voice, :video, :location, :link, :event, :fallback]中之一，为一个hash数组
      #value : 为调用具体返回信息的值
      def match_responders responders, value
        mat = responders.inject({scoped:nil, general:nil}) do |matched, responder|
          condition = responder[:with]

          if condition.nil?
            matched[:general] ||= [responder, value]
            next matched
          end

          if condition.is_a? Regexp
            matched[:scoped] ||= [responder] + $~.captures if(value =~ condition)
          else
            matched[:scoped] ||= [responder, value] if(value == condition)
          end
          matched
        end
        return mat[:scoped] || mat[:general]
      end
    end


    def show
      render :text => params[:echostr]
    end

    def create
      req = WeichatRails::Message.from_hash(params[:xml] || post_xml)
      response = self.class.responder_for(req) do |responder, *args|
        responder ||= self.class.responders(:fallback).first

        next if responder.nil?
        next req.reply.text responder[:respond] if (responder[:respond])
        next responder[:proc].call(*args.unshift(req)) if (responder[:proc])
      end

      if response.respond_to? :to_xml
        render xml: response.to_xml
      else
        render :nothing => true, :status => 200, :content_type => 'text/html'
      end
    end

    private
    def verify_signature
      array = [self.token, params[:timestamp], params[:nonce]].compact.sort
      render :text => "Forbidden", :status => 403 if params[:signature] != Digest::SHA1.hexdigest(array.join)
    end

    def post_xml
      data = Hash.from_xml(reqest.raw_post)
      HashWithIndifferentAccess.new_from_hash_copying_default data.fetch('xml', {})
    end


    def wechat_model
      @wechat_model || WeichatRails.config.public_account_class.constantize
    end

    #TODO init wechat when need to admin account
    def init_wechat_or_token
      raise NotImplementedError, "controller must implement init_wechat_or_token method!if you just need reply,you can init the token,otherwise you need to init whchat and token like: wechat = Wechat::Api.new(opts[:appid], opts[:secret], opts[:access_token]) token = opts[:token]
      "
    end

  end
end

