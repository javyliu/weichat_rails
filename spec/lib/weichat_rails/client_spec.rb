require 'spec_helper'

RSpec.describe WeichatRails::Client do
  subject { WeichatRails::Client.new('http://host/',20,false) }

  let(:response_params) do
    {
      headers: {content_type: 'text/plain'},
      status: 200
    }
  end

  let(:response_404) { double '404', response_params.merge(status: 404) }
  let(:response_text) { double 'text', response_params.merge(body: 'some text') }
  let(:response_json) { double 'json', response_params.merge(body: {result: 'success'}.to_json, headers: {content_type: 'application/json'}) }
  let(:response_image) { double 'image', response_params.merge(body: 'image data', headers: {content_type: 'image/gif'}) }

  describe '#get' do
    it 'will use http get method to request data' do
      allow(HTTP).to receive_message_chain('headers.get') {response_json}
      subject.get('token')
    end
  end

  describe '#post' do
    it 'Will use http post method to request data' do
      allow(HTTP).to receive_message_chain('headers.post') {response_json}
      subject.post('token','some_data')
    end
  end

  describe '#request' do
    it 'will add accept => :json for request' do
      block = lambda do |url, headers|
        expect(url).to eq('http://host/token')
        expect(headers).to eq(params: { access_token: '1234'}, 'Accept' => 'application/json')
        response_json
      end

      subject.send(:request, 'token', params: {access_token: '1234'}, &block )
    end

    it 'will use base option to construct url' do
      block = lambda do |url,_headers|
        expect(url).to eq('http://override/token')
        response_json
      end
      subject.send(:request, 'token', base: 'http://override/', &block)

    end

    it 'will not pass as option for request' do
      block = lambda do |_url,headers|
        expect(headers[:as]).to be_nil
        response_json
      end
      subject.send(:request, 'token', as: :text, &block)

    end

    it 'will raise error if response code is not 200' do
      expect { subject.send(:request, 'token'){ response_404} }.to raise_error(/Request not OK/)
    end


    context 'parse response body' do
      it 'will return response body for text response' do
        expect(subject.send(:request, 'text', as: :text){ response_text }).to  eq(response_text.body)
      end

      it 'will return response body as file for image' do
        expect(subject.send(:request, 'image'){ response_image }).to be_a(Tempfile)
      end

      it 'will return response body as file for unknown content_type' do
        response_stream = double 'image', response_params.merge(body: 'stream', headers: {content_type: 'stream'})
        expect(subject.send(:request, 'image', as: :file){response_stream}).to be_a(Tempfile)
      end

    end

    context 'json error' do
      it 'raise ResponseError given response has error json' do
        allow(response_json).to receive(:body).and_return({ errcode: 1106, errmsg: 'error message'}.to_json)
        expect { subject.send(:request, 'image', as: :file){response_json} }.to raise_error(WeichatRails::ResponseError)
      end

      it 'raise AccessTokenExpiredError given response has error json with errorcode 40014' do
        allow(response_json).to receive(:body).and_return( {errcode: 40014, errmsg: 'error_message'}.to_json )
        expect { subject.send(:request, 'image', as: :file) {response_json} }.to raise_error(WeichatRails::AccessTokenExpiredError)
      end
    end

  end

end
