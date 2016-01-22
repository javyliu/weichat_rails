require 'spec_helper'

RSpec.describe WeichatRails::Api do

  subject do
    WeichatRails::Api.new('appid','secret',20,false)
  end

  before :each do
    allow(subject.access_token).to receive(:token).and_return('access_token')
  end

  describe '#client.base' do
    it 'with get correct API_BASE' do
      expect(subject.client.base).to eq WeichatRails::Api::API_BASE
    end
  end

  describe '#callbackip' do
    it 'will get callbackip with access_token' do
      server_ip_result  = 'server_ip_result'
      expect(subject.client).to receive(:get).with('getcallbackip', params: { access_token: 'access_token'}).and_return(server_ip_result)
      expect(subject.callbackip).to eq server_ip_result

    end
  end

  describe '#qcode' do
    it 'will get showqrcode with ticket at file based api endpoint as file' do
      ticket_result = 'ticket_result'

      expect(subject.client).to receive(:get).with('showqrcode', params: {ticket: 'ticket'}, base: WeichatRails::Api::MP_BASE, as: :file).and_return(ticket_result)

      expect(subject.qrcode('ticket')).to eq(ticket_result)
    end
  end

  describe '#groups' do
    before :each do
      @groups_result = 'groups_result'
      expect(subject.client).to receive(:get).with('groups/get', params: {access_token: 'access_token'}).and_return(@groups_result)
    end

    it 'will get groups with access_token' do
      expect(subject.groups).to eq(@groups_result)
    end

    it 'will get groups with access_token by groups alias' do
      expect(subject.group_get).to eq(@groups_result)
    end
  end

  describe '#group_create' do
    it 'will post groups/create with access_token and new group json_data' do
      new_group = { group: {name: 'new_group_name'}}
      expect(subject.client).to receive(:post).with('groups/create', new_group.to_json, params: {access_token: 'access_token'} ).and_return(true)
      expect(subject.group_create('new_group_name')).to be_truthy
    end
  end

  describe '#group_update' do
    before :each do
      update_group = { group: {id: 108, name: 'test2_modify'}}
      expect(subject.client).to receive(:post).with('groups/update', update_group.to_json, params: {access_token: 'access_token'}).and_return(true)
    end

    it 'will post groups/update with access_token and json_data' do
      expect(subject.group_update(108,'test2_modify')).to be_truthy
    end

    it 'will post group/update with access_token and json_data by alias method group_name_update' do
      expect(subject.group_name_update(108, 'test2_modify')).to be_truthy
    end
  end


  describe '#group_delete' do
    it 'will post groups/delete with access_token' do
      delete_group = {group: {id: 108}}
      expect(subject.client).to receive(:post).with('groups/delete', delete_group.to_json, params: {access_token: 'access_token'}).and_return(true)
      expect(subject.group_delete(108)).to be_truthy
    end
  end


  describe '#users' do
    it 'will get user/get with access_token' do
      users_result = "users_result"
      expect(subject.client).to receive(:get).with('user/get', params: {access_token: 'access_token'}).and_return(users_result)
      expect(subject.users).to eq(users_result)
    end

    it 'will get user/get with access_token and next_openid' do
      users_result = 'users_result'
      expect(subject.client).to receive(:get).with('user/get', params: {access_token: 'access_token', next_openid: 'next_openid'}).and_return(users_result)
      expect(subject.users('next_openid')).to eq(users_result)

    end
  end


  describe '#user' do
    it 'will get user/info with access_token and openid' do
      user_result = 'user_result'
      expect(subject.client).to receive(:get).with('user/info', params: {access_token: 'access_token', openid: 'openid'}).and_return(user_result)
      expect(subject.user('openid')).to eq(user_result)
    end
  end

  describe '#user_group' do
    it 'will post groups/getid with access_token and openid to get user groups info' do
      user_request = {openid: 'openid'}
      user_response = {gruopid: 102}
      expect(subject.client).to receive(:post).with('groups/getid', user_request.to_json, params: {access_token: 'access_token'}).and_return(user_response)
      expect(subject.user_group('openid')).to eq(user_response)
    end
  end

  describe '#user_change_group' do
    it 'will post groups/members/update with access_token and openid to get user groups info' do
      user_request = {openid: 'openid', to_groupid: 108}
      expect(subject.client).to receive(:post).with('groups/members/update', user_request.to_json, params: {access_token: 'access_token'}).and_return(true)
      expect(subject.user_change_group('openid',108)).to be_truthy
    end
  end

  describe '#user_update_remark' do
    it 'will post groups/info/updatermark with access_token and openid to set user remark' do
      user_update_remark_request = {openid: 'openid', remark: 'remark'}
      user_update_remark_result = {errorcode: 0, errmsg: 'ok'}
      expect(subject.client).to receive(:post).with('user/info/updateremark', user_update_remark_request.to_json, params: {access_token: 'access_token'}).and_return(user_update_remark_result)
      expect(subject.user_update_remark('openid','remark')).to eq(user_update_remark_result)
    end
  end

  describe '#qrcode_create_scene' do
    it 'will post qrcode/create with access_token, scene_id and expire_seconds' do
      scene_id = 101
      qrcode_scene_res = {expire_seconds: 60, action_name: 'QR_SCENE', action_info: {scene: {scene_id: scene_id}}}
      qrcode_scene_result = {ticket: 'qr_code_ticket', expire_seconds: 60, url: 'qr_code_ticket_pic_url'}
      expect(subject.client).to receive(:post).with('qrcode/create', qrcode_scene_res.to_json, params: {access_token: 'access_token'}).and_return(qrcode_scene_result)
      expect(subject.qrcode_create_scene(scene_id, 60)).to eq(qrcode_scene_result)
    end
  end


  describe '#qrcode_create_limit_scene' do
    qrcode_limit_scene_result = {ticket: 'qr_code_ticket', url: 'qr_code_ticket_pic_url'}

    it 'will post qrcode/create with access_token and scene_id' do
      scene_id = 101
      qrcode_limit_scene_req = {action_name: 'QR_LIMIT_SCENE', action_info: {scene: {scene_id: scene_id}}}
      expect(subject.client).to receive(:post).with('qrcode/create', qrcode_limit_scene_req.to_json, params: {access_token: 'access_token'}).and_return(qrcode_limit_scene_result)
      expect(subject.qrcode_create_limit_scene(scene_id)).to eq(qrcode_limit_scene_result)
    end

    it 'will post qrcode/create with access_token and scene_str' do
      scene_str = 'scene_str'
      qrcode_limit_str_scene_req = {action_name: 'QR_LIMIT_STR_SCENE', action_info: {scene: {scene_str: scene_str}}}
      expect(subject.client).to receive(:post).with('qrcode/create', qrcode_limit_str_scene_req.to_json, params: {access_token: 'access_token'}).and_return(qrcode_limit_scene_result)
      expect(subject.qrcode_create_limit_scene(scene_str)).to eq(qrcode_limit_scene_result)
    end
  end

  describe '#menu' do
    it 'will get menu/get with access_token' do
      menu_result = 'menu_result'
      expect(subject.client).to receive(:get).with('menu/get', params: {access_token: 'access_token'}).and_return(menu_result)
      expect(subject.menu).to eq(menu_result)
    end
  end

  describe '#menu_create' do
    it 'will post menu/create with access_token and json_data' do
      menu = {buttons: ['a_button']}
      expect(subject.client).to receive(:post).with('menu/create', menu.to_json, params: {access_token: 'access_token'}).and_return(true)
      expect(subject.menu_create(menu)).to be true
    end
  end

  describe '#menu_delete' do
    it 'will get menu/delete with access_token' do
      expect(subject.client).to receive(:get).with('menu/delete', params: {access_token: 'access_token'}).and_return(true)
      expect(subject.menu_delete).to be true
    end
  end

  describe '#media' do
    it 'will get media/get with access_token and media_id at file based api endpoint as file' do
      media_result = 'media_result'
      expect(subject.client).to receive(:get).with('media/get', params: {access_token: 'access_token', media_id: 'media_id'}, as: :file).and_return(media_result)
      expect(subject.media('media_id')).to eq(media_result)

    end
  end

  describe '#media_create' do
    it 'will post media/upload with access_token,type and media payload at file based api endpoint' do
      file = "README.md"
      expect(subject.client).to receive(:post_file).with('media/upload',file, params: {type: 'image', access_token: 'access_token'}).and_return(true)
      expect(subject.media_create('image',file)).to be true
    end
  end

  describe '#material' do
    it 'will get material/get with access_token and media_id at file based api endpoint as file' do
      material_result = 'material_result'
      expect(subject.client).to receive(:get).with('material/get', params: {access_token: 'access_token', media_id: 'media_id'}, as: :file).and_return(material_result)
      expect(subject.material('media_id')).to eq(material_result)
    end
  end

  describe '#material_count' do
    it 'will get material_count with access_token' do
      material_count_result = {voice_count: 1, video_count: 2, image_count: 3, news_count: 4}
      expect(subject.client).to receive(:get).with('material/get_materialcount', params: { access_token: 'access_token'}).and_return(material_count_result)
      expect(subject.material_count).to eq(material_count_result)

    end
  end

  describe '#material_list' do
    it 'will get material list with access_token' do
      material_list_request = {type: 'image', offset: 0, count: 20}
      material_list_result = {total_count: 1, item_count: 1, item: [{media_id: 'media_id', name: 'name', update_time: 12345, url: 'url'}]}
      expect(subject.client).to receive(:post).with('material/batchget_material', material_list_request.to_json, params: { access_token: 'access_token'}).and_return(material_list_result)
      expect(subject.material_list('image', 0, 20)).to eq(material_list_result)
    end
  end

  describe '#material_add' do
    it 'will post material/add_material with access_token, type and media payload at file based api endpoint' do
      file = "README.md"
      expect(subject.client).to receive(:post_file).with('material/add_material', file, params: {type: 'image', access_token: 'access_token'}).and_return(true)
      expect(subject.material_add('image',file)).to be true
    end
  end

  describe '#material_delete' do
    it 'will post material/del_material with access_token and media_id in payload' do
      media_id = 'media_id'
      material_delete_result = {errcode: 0, errmsg: 'deleted'}
      expect(subject.client).to receive(:post).with('material/del_material', {media_id: media_id}, params: {access_token: 'access_token'}).and_return(material_delete_result)
      expect(subject.material_delete(media_id)).to eq(material_delete_result)
    end
  end

  describe '#custom_message_send' do
    it 'will post message/custom/send with access_token, and json payload' do
      payload = {touser: 'openid', msgtype: 'text', text: {content: 'message content'}}
      expect(subject.client).to receive(:post).with('message/custom/send', payload.to_json, params: { access_token: 'access_token'}, content_type: :json).and_return(true)
      expect(subject.custom_message_send(WeichatRails::Message.to('openid').text('message content'))).to be true
    end
  end

  describe '#template_message_send' do
    it 'will post message/template/send with access_token, and json payload' do
      payload = { touser: 'OPENID',
                  template_id: 'ngqIpbwh8bUfcSsECmogfXcV14J0tQlEpBO27izEYtY',
                  url: 'http://weixin.qq.com/download',
                  topcolor: '#FF0000',
                  data: { first: { value: '恭喜你购买成功！', color: '#173177' },
                          keynote1: { value: '巧克力', color: '#173177' },
                          keynote2: { value: '39.8元', color: '#173177' },
                          keynote3: { value: '2014年9月16日', color: '#173177' },
                          remark: { value: '欢迎再次购买！', color: '#173177' } } }
      response_result = { errcode: 0, errmsg: 'ok', msgid: 332 }

      expect(subject.client).to receive(:post).with('message/template/send', payload.to_json, params: {access_token: 'access_token'},content_type: :json).and_return(response_result)
      expect(subject.template_message_send(payload)).to eq(response_result)
    end
  end



end
