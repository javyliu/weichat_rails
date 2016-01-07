require 'weichat_rails/client'
require 'weichat_rails/access_token'

class WeichatRails::Api
  attr_reader :access_token, :client

  API_BASE = "https://api.weixin.qq.com/cgi-bin/"
  #FILE_BASE = "http://file.api.weixin.qq.com/cgi-bin/"
  KEFU_BASE = "https://api.weixin.qq.com/customservice/"
  MP_BASE = 'https://mp.weixin.qq.com/cgi-bin/'
  #https://api.weixin.qq.com/cgi-bin/customservice/getkflist?access_token=ACCESS_TOKEN

  def initialize appid, secret,timeout = 20,skip_verify_ssl = true
    @client = WeichatRails::Client.new(API_BASE,timeout,skip_verify_ssl)
    @access_token = WeichatRails::AccessToken.new(@client, appid, secret)
  end

  def callbackip
    get 'getcallbackip'
  end

  def groups
    get 'groups/get'
  end
  alias_method :group_get,:groups

  def group_create(group_name)
    post 'groups/create', JSON.generate(group: { name: group_name })
  end

  def group_update(groupid, new_group_name)
    post 'groups/update', JSON.generate(group: { id: groupid, name: new_group_name })
  end
  alias_method :group_name_update,:group_update

  def group_delete(groupid)
    post 'groups/delete', JSON.generate(group: { id: groupid })
  end

  def users(nextid = nil)
    params = { params: { next_openid: nextid } } if nextid.present?
    get('user/get', params || {})
  end

  def user(openid)
    get 'user/info', params: { openid: openid }
  end

  def user_group(openid)
    post 'groups/getid', JSON.generate(openid: openid)
  end
  alias_method :group_user_id,:user_group

  def user_change_group(openid, to_groupid)
    post 'groups/members/update', JSON.generate(openid: openid, to_groupid: to_groupid)
  end

  def user_update_remark(openid, remark)
    post 'user/info/updateremark', JSON.generate(openid: openid, remark: remark)
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


  def get_duokefu_records time,pageindex
    json_str = JSON.generate({starttime: time.beginning_of_day.to_i,endtime: time.end_of_day.to_i,pagesize: 10,pageindex: pageindex})
    post("msgrecord/getrecord",json_str,base: KEFU_BASE)
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
  #def media media_id
  #  get "media/get", params:{media_id: media_id}, base: FILE_BASE, as: :file
  #end

  #def media_create type, file
  #  post "media/upload", {upload:{media: file}}, params:{type: type}, base: FILE_BASE
  #end

  def media(media_id)
    get 'media/get', params: { media_id: media_id }, as: :file
  end

  def media_create(type, file)
    post_file 'media/upload', file, params: { type: type }
  end

  def material(media_id)
    get 'material/get', params: { media_id: media_id }, as: :file
  end

  def material_count
    get 'material/get_materialcount'
  end

  def material_list(type, offset, count)
    post 'material/batchget_material', JSON.generate(type: type, offset: offset, count: count)
  end

  def material_add(type, file)
    post_file 'material/add_material', file, params: { type: type }
  end

  def material_delete(media_id)
    post 'material/del_material', media_id: media_id
  end

  def custom_message_send(message)
    post 'message/custom/send', message.to_json, content_type: :json
  end

  def template_message_send(message)
    post 'message/template/send', message.to_json, content_type: :json
  end

  def qrcode(ticket)
    client.get 'showqrcode', params: { ticket: ticket }, base: MP_BASE, as: :file
  end

  def qrcode_create_scene(scene_id, expire_seconds = 604800)
    post 'qrcode/create', JSON.generate(expire_seconds: expire_seconds,
                                        action_name: 'QR_SCENE',
                                        action_info: { scene: { scene_id: scene_id } })
  end

  def qrcode_create_limit_scene(scene_id_or_str)
    case scene_id_or_str
    when Fixnum
      post 'qrcode/create', JSON.generate(action_name: 'QR_LIMIT_SCENE',
                                          action_info: { scene: { scene_id: scene_id_or_str } })
    else
      post 'qrcode/create', JSON.generate(action_name: 'QR_LIMIT_STR_SCENE',
                                          action_info: { scene: { scene_str: scene_id_or_str } })
    end
  end

  # http://mp.weixin.qq.com/wiki/17/c0f37d5704f0b64713d5d2c37b468d75.html
  # 第二步：通过code换取网页授权access_token
  def web_access_token(code)
    params = {
      appid: access_token.appid,
      secret: access_token.secret,
      code: code,
      grant_type: 'authorization_code'
    }
    get 'access_token', params: params, base: OAUTH2_BASE
  end

  protected
  def get path, headers={}
    with_access_token(headers[:params]){|params| client.get path, headers.merge(params: params)}
  end

  def post path, payload, headers = {}
    with_access_token(headers[:params]){|params| client.post path, payload, headers.merge(params: params)}
  end

  def post_file(path, file, headers = {})
    with_access_token(headers[:params]) do |params|
      client.post_file path, file, headers.merge(params: params)
    end
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

