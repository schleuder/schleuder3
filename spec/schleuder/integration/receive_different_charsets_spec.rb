require 'spec_helper'

describe 'user sends emails with different charsets' do
  Dir['spec/fixtures/mails/charset_mails/*.eml'].each do |f|
    it "works with #{File.basename(f,'.eml')}" do
      start_smtp_daemon
      list = create(:list)
      list.subscribe('admin@example.org', nil, true)

      # Clean any LANG from env as this is usually the case for MUAs
      # https://0xacab.org/schleuder/schleuder/issues/409
      with_env(ENV.delete_if {|key, value| key =~ /LANG/ || key =~ /LC/ }) do
        error = run_schleuder(:work, list.email, f)
        mails = Dir.glob("#{smtp_daemon_outputdir}/mail-*")

        expect(error).to be_empty
        expect(mails.size).to eq 1
      end

      stop_smtp_daemon
    end
  end
end


