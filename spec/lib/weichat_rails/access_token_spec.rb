require 'spec_helper'

RSpec.describe WeichatRails::AccessToken do
  let(:token) { '12345' }
  let(:client) { double(:client) }

  subject { WeichatRails::AccessToken.new(client,'appid','secret') }

  before :each do
    allow(client).to receive(:get).with('token', params: {grant_type: 'client_credential', appid: 'appid', secret: 'secret'})
    .and_return("access_token" =>  '12345', "expires_in" =>  7200)
  end

  after :each do
    WeichatRails.config.cache.delete(subject.appid)
  end

  describe '#token' do
    it 'read from mamcache if access_token is not initialized' do
      WeichatRails.config.cache.set(subject.appid,'12345',7200)
      expect(subject.token).to eq('12345')
    end

    it "refresh access_token if token file did'n exist" do
      expect(WeichatRails.config.cache.get(subject.appid)).to be nil
      expect(subject.token).to eq('12345')
      expect(WeichatRails.config.cache.get(subject.appid)).to eq('12345')
    end

    it 'raise exception if token failed' do
      allow(client).to receive(:get).and_raise('error')
      expect{subject.token}.to raise_error('error')
    end
  end

  describe '#refresh' do
    it 'will delete access_token' do
      expect(subject.refresh).to eq(WeichatRails.config.cache.get(subject.appid))
      expect(subject.token).to eq('12345')
    end

  end





end
