require 'weichat_rails/client'
require 'weichat_rails/access_token'

class WeichatRails::Api
  attr_reader :access_token, :client

  API_BASE = "https://api.weixin.qq.com/cgi-bin/"
  FILE_BASE = "http://file.api.weixin.qq.com/cgi-bin/"
  #https://api.weixin.qq.com/cgi-bin/customservice/getkflist?access_token=ACCESS_TOKEN

  def initialize appid, secret
    @client = WeichatRails::Client.new(API_BASE)
    @access_token = WeichatRails::AccessToken.new(@client, appid, secret)
  end

  def users
    get("user/get")
  end

  def user openid
    get("user/info", params:{openid: openid})
  end

  def menu
    get("menu/get")
  end

  def menu_delete
    get("menu/delete")
  end

  def kefulist
    get("customservice/getkflist")
  end

  def group_get
    get("groups/get")
  end

  def group_user_id openid
    post "groups/getid",params:{openid: openid}
  end

  def group_update openid, to_groupid
    post "groups/members/update",params:{openid: openid,to_groupid: to_groupid}, content_type: :json
  end

  def menu_create menu
    # 微信不接受7bit escaped json(eg \uxxxx), 中文必须UTF-8编码, 这可能是个安全漏洞
    # 如果是rails4.0以上使用 to_json 即可，否则使用 JSON.generate(menu,:ascii_only => false)
    # 但以上试过之后仍是不行，在rails c中却是可以的，所以因该是被其它旧版本的json gem给重写了，所以采用以下方法
    # 原因找到了是：
    # 如果传的hash为ActiveSupport::HashWithIndifferentAccess 对像，因为用的是3.2.19，所以其编码可能不对
    # 直接用 Hash对像的话，用的是ruby 2.0 的方法，做JSON.generate的时候对中文不会再编码成 \uxxxx的形式
    #
    json_str = JSON.generate(menu)#.gsub!(/\\u([0-9a-z]{4})/){|u| [$1.to_i(16)].pack('U')}

    post("menu/create", json_str)
  end

  #返回媒体文件
  def media media_id
    get "media/get", params:{media_id: media_id}, base: FILE_BASE, as: :file
  end

  def media_create type, file
    post "media/upload", {upload:{media: file}}, params:{type: type}, base: FILE_BASE
  end

  def custom_message_send message
    post "message/custom/send", message.to_json, content_type: :json
  end


  protected
  def get path, headers={}
    with_access_token(headers[:params]){|params| client.get path, headers.merge(params: params)}
  end

  def post path, payload, headers = {}
    with_access_token(headers[:params]){|params| client.post path, payload, headers.merge(params: params)}
  end

  def with_access_token params={}, tries=2
    begin
      params ||= {}
      yield(params.merge(access_token: access_token.token))
    rescue WeichatRails::AccessTokenExpiredError
      access_token.refresh
      retry unless (tries -= 1).zero?
    end
  end

end

