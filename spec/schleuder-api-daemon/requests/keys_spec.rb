require 'helpers/api_daemon_spec_helper'

describe 'keys via api' do

  before :each do
    @list = List.last || create(:list)
  end

  context 'list' do
    it 'doesn\'t list keys without authentication' do
      get "/keys.json?list_id=#{@list.id}"
      expect(last_response.status).to be 401
    end
    it 'does list keys with authentication' do
      authorize!
      get "/keys.json?list_id=#{@list.id}"
      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body).length).to be 1
    end
  end
  context 'check' do
    it 'doesn\'t check keys without authentication' do
      get "/keys/check_keys.json?list_id=#{@list.id}"
      expect(last_response.status).to be 401
    end
    it 'does check keys with authorization' do
      @list.import_key(File.read("spec/fixtures/revoked_key.txt"))
      @list.import_key(File.read("spec/fixtures/signonly_key.txt"))
      @list.import_key(File.read("spec/fixtures/expired_key.txt"))
      authorize!
      get "/keys/check_keys.json?list_id=#{@list.id}"
      expect(last_response.status).to be 200
      result = JSON.parse(last_response.body)['result']
      expect(result).to include("This key is expired:\n0x98769E8A1091F36BD88403ECF71A3F8412D83889")
      expect(result).to include("This key is revoked:\n0x7E783CDE6D1EFE6D2409739C098AC83A4C0028E9")
      expect(result).to include("This key is not capable of encryption:\n0xB1CD8BB15C2673C6BFD8FA4B70B2CF29E01AD53E")

      @list.delete_key('0x70B2CF29E01AD53E')
      @list.delete_key('0x098AC83A4C0028E9')
      @list.delete_key('0x70B2CF29E01AD53E')
    end
  end

  context 'export' do
    it 'doesn\'t export keys without authentication' do
      get "/keys.json?list_id=#{@list.id}"
      expect(last_response.status).to be 401
    end
    it 'does list keys with authentication' do
      authorize!
      get "/keys.json?list_id=#{@list.id}"
      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body).length).to be 1
    end
  end

  context 'import' do
    it 'doesn\'t import keys without authentication' do
      parameters = {'list_id' => @list.id, 'keymaterial' => File.read('spec/fixtures/bla_foo_key.txt') }
      expect {
        post '/keys.json', parameters.to_json
        expect(last_response.status).to be 401
      }.to change{ @list.keys.length }.by 0
    end
    it 'does list keys with authentication' do
      authorize!
      parameters = {'list_id' => @list.id, 'keymaterial' => File.read('spec/fixtures/bla_foo_key.txt') }
      expect {
        post '/keys.json', parameters.to_json
        expect(last_response.status).to be 200
      }.to change{ @list.keys.length }.by 1
      @list.delete_key('0xEBDBE899251F2412')
    end
  end

  context 'delete' do
    before(:each) do
      @list.import_key(File.read("spec/fixtures/bla_foo_key.txt"))
    end

    it 'doesn\'t delete keys without authentication' do
      expect {
        delete "/keys/0xEBDBE899251F2412.json?list_id=#{@list.id}"
        expect(last_response.status).to be 401
      }.to change{ @list.keys.length }.by 0
      @list.delete_key('0xEBDBE899251F2412')
    end
    it 'does delete keys with authentication' do
      authorize!
      expect {
        delete "/keys/0xEBDBE899251F2412.json?list_id=#{@list.id}"
        expect(last_response.status).to be 200
      }.to change{ @list.keys.length }.by(-1)
    end
  end

  context 'a key with broken utf8 in uid' do
    context 'already imported' do
      before(:each) do
        @list.import_key(File.read("spec/fixtures/broken_utf8_uid_key.txt"))
      end
      after(:each) do
        @list.delete_key('0x1242F6E13D8EBE4A')
      end
      it 'does list this key' do
        authorize!
        get "/keys.json?list_id=#{@list.id}"
        expect(last_response.status).to be 200
        expect(JSON.parse(last_response.body).length).to be 2
      end
      it 'does get key' do
        authorize!
        get "/keys/0x1242F6E13D8EBE4A.json?list_id=#{@list.id}"
        expect(last_response.status).to be 200
        expect(JSON.parse(last_response.body)['fingerprint']).to eq("3102B29989BEE703AE5ED62E1242F6E13D8EBE4A")
      end
      it 'does delete key' do
        authorize!
        expect {
          delete "/keys/0x1242F6E13D8EBE4A.json?list_id=#{@list.id}"
          expect(last_response.status).to be 200
        }.to change{ @list.keys.length }.by(-1)
      end
    end
    it 'does add key' do
      authorize!
      parameters = {'list_id' => @list.id, 'keymaterial' => File.read('spec/fixtures/broken_utf8_uid_key.txt') }
      expect {
        post '/keys.json', parameters.to_json
        expect(last_response.status).to be 200
      }.to change{ @list.keys.length }.by(1)
    end
  end
end
