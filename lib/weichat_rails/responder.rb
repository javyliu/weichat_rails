module WeichatRails
  module Responder
    extend ActiveSupport::Concern

    included do
      # Rails 5 API mode won't define verify_authenticity_token
      if defined?(:skip_before_action)
        before_action :init_wechat_or_token
        skip_before_action :verify_authenticity_token unless defined?(:verify_authenticity_token)
        before_action :verify_signature, only: [:show, :create]
      else
        before_filter :init_wechat_or_token
        skip_before_filter :verify_authenticity_token
        before_filter :verify_signature, only: [:show, :create]
      end
    end

    attr_accessor :wechat, :token,:wechat_user


    module ClassMethods

      #定义整体的处理规则，对于不同的message_type,在block块中进行返回数据处理，
      #on :text do |res,content|
      #
      #end
      #def on message_type, with: nil, respond: nil, &block
      #  raise "Unknow message type" unless message_type.in? [:text, :image, :voice, :video, :location, :link, :event, :fallback]
      #  config=respond.nil? ? {} : {:respond=>respond}
      #  config.merge!(:proc=>block) if block_given?

      #  if (with.present? && !message_type.in?([:text, :event]))
      #    raise "Only text and event message can take :with parameters"
      #  else
      #    config.merge!(:with=>with) if with.present?
      #  end

      #  responders(message_type) << config
      #  return config
      #end

      #def responders type
      #  @responders ||= Hash.new
      #  @responders[type] ||= Array.new
      #end


      #指定的过滤方法，默认不使用指定的匹配方法,如为true,
      def use_matcher mat = false
        @use_matcher = mat
      end

      def use_matcher?
        @use_matcher
      end

      #用于处理用户请求，该方法只关注用户信息类型及用户请求的内容或事件信息
      #事件类型：subscribe(订阅)、unsubscribe(取消订阅),SCAN(关注后扫描)，LOCATION（上报地理位置）,CLICK(自定义菜单事件),VIEW(点击菜单跳转链接时的事件推送)
      def responder_for message, &block
        message_type = message[:MsgType].to_sym
        #responders = responders(message_type)
        #if use_matcher?
        responder = {:method => :find_matcher}
        case message_type
        when :text
          yield(responder,message[:Content])
        when :event
          yield(responder,message[:Event],message[:EventKey])
        when :image,:voice,:shortvideo
          yield(responder,'MEDIA',picurl: message[:PicUrl],media_id: message[:MediaId])
        else
          yield(responder)
        end
        #else
        #  case message_type
        #  when :text
        #    yield(* match_responders(responders, message[:Content]))
        #  when :event
        #    yield(* match_responders(responders, message[:Event]))
        #  else
        #    yield(responders.first)
        #  end
        #end
      end

      private

      #该方法用于确定预先用on定义的返回信息(一个数组 [{with:,proc:,respond:},*args])做循环处理
      #responds : 预先定义的某类返回信息,类型为[:text, :image, :voice, :video, :location, :link, :event, :fallback]中之一，为一个hash数组
      #value : 请求内容
      #优先返回具有with值的on规则
      #注：使用on定义的规则只适用于直接在控制器中写死的规则，属于类级别，不适用于后台配置类型,如果responders[msg_type]为空的情况下不产生任何内容
      #def match_responders responders, value
      #  mat = responders.inject({scoped:nil, general:nil}) do |matched, responder|
      #    condition = responder[:with]

      #    if condition.nil?
      #      matched[:general] ||= [responder, value]
      #      next matched
      #    end

      #    if condition.is_a? Regexp
      #      matched[:scoped] ||= [responder] + $~.captures if(value =~ condition)
      #    else
      #      matched[:scoped] ||= [responder, value] if(value == condition)
      #    end
      #    matched
      #  end
      #  return mat[:scoped] || mat[:general]
      #end

    end


    #用于公众号开发者中心服务器配置中的URL配置,其中xxx为该公众号在开发者数据库中的唯一识别码，由auto_generate_secret_key 来产生
    #如：http://m.pipgame.com/wx/xxxxx
    def show
      render :text => params[:echostr]
    end

    #创建两个message对像，原请求message及返回message信息，返回的message中传入当前公众号对像，用于回调函数中访问该公众号在数据库中的配置信息
    def create
      req = WeichatRails::Message.from_hash(params[:xml] || post_xml)
      #add whchat_user for multiplay wechat user
      #req.wechat_user(self.wechat_user)
      #如果是多客服消息，直接返回
      response = self.class.responder_for(req) do |responder, *args|
        responder ||= self.class.responders(:fallback).first

        #next method(responder[:method]).call(*args.unshift(req)) if (responder[:method])
        next if responder.nil?
        next find_matcher(*args.unshift(req)) if (responder[:method])
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
      data = Hash.from_xml(request.raw_post)
      HashWithIndifferentAccess.new_from_hash_copying_default data.fetch('xml', {})
    end


    #def wechat_model
    #@wechat_model || WeichatRails.config.public_account_class.constantize
    #end

    #TODO init wechat , wechat_user,token from database
    def init_wechat_or_token
      raise NotImplementedError, "controller must implement init_wechat_or_token method!if you just need reply,you can init the token,otherwise you need to init whchat and token like: wechat = Wechat::Api.new(opts[:appid], opts[:secret], opts[:access_token]) token = opts[:token]
      "
    end

    #need to inplement
    #在这里处理不同值的内容匹配：subscribe(订阅)、unsubscribe(取消订阅),SCAN(关注后扫描)，LOCATION（上报地理位置）,CLICK(自定义菜单事件),VIEW(点击菜单跳转链接时的事件推送)
    def find_matcher(req,keyword,event_key=nil)
      raise NotImplementedError, "controller must implement find_matcher method,eg: get matcher content from database"
    end

  end
end

