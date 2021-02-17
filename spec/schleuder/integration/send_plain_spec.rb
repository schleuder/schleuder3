require 'spec_helper'

describe 'user sends a plain text message' do
  [
    'plain',
    'signed-inline',
    'signed-mime',
  ].each do |t|
    it "from thunderbird being #{t}" do
      list = create(:list, send_encrypted_only: false)
      list.subscribe('admin@example.org', nil, true)
      list.import_key(File.read('spec/fixtures/openpgpkey_52507B0163A8D9F0094FFE03B1A36F08069E55DE.asc'))
      mail = Mail.read("spec/fixtures/mails/#{t}/thunderbird.eml")
      error = nil

      begin
        Schleuder::Runner.new().run(mail.to_s, list.email)
      rescue SystemExit => exc
        error = exc
      end
      mails = Mail::TestMailer.deliveries

      expect(error).to be_nil
      expect(mails.size).to eq 1
      content = mails.first.parts[0].parts[1].to_s
      expect(content).not_to include('-----BEGIN PGP SIGNATURE-----')
    end
  end
end

