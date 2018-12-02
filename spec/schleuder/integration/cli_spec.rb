require "spec_helper"

describe 'cli' do
  context '#refresh_keys' do
    it 'updates keys from the keyserver' do
      list = create(:list)
      list.subscribe("admin@example.org", nil, true)
      list.import_key(File.read("spec/fixtures/expired_key.txt"))
      list.import_key(File.read("spec/fixtures/olduid_key.txt"))

      with_sks_mock(list.listdir) do
        Cli.new.refresh_keys
        dirmngr_pid = `pgrep -a dirmngr | grep #{list.listdir}`.split(' ',2).first
        expect(dirmngr_pid).to be_nil
      end
      mail = Mail::TestMailer.deliveries.find { |message| message.to == [list.admins.first.email] }

      b = mail.first_plaintext_part.body.to_s
      expect(b).to match(/Refreshing all keys from the keyring of list #{list.email} resulted in this:\n\n/)
      expect(b).to match(/\nThis key was updated \(new signatures\):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo \d{4}-\d{2}-\d{2} \[expired: \d{4}-\d{2}-\d{2}\]\n/)
      expect(b).to match(/\nThis key was updated \(new user-IDs and new signatures\):\n0x6EE51D78FD0B33DE65CCF69D2104E20E20889F66 new@example.org \d{4}-\d{2}-\d{2}\n/)

      teardown_list_and_mailer(list)
    end
    it 'updates keys from the keyserver for only a specific list' do
      list1 = create(:list)
      list2 = create(:list)
      [list1,list2].each do |list|
        list.subscribe("admin@example.org", nil, true)
        list.import_key(File.read("spec/fixtures/expired_key.txt"))
        list.import_key(File.read("spec/fixtures/olduid_key.txt"))
      end

      with_sks_mock(list1.listdir) do
        Cli.new.refresh_keys list1.email
      end
      mail = Mail::TestMailer.deliveries.find { |message| message.to == [list1.admins.first.email] }

      b = mail.first_plaintext_part.body.to_s
      expect(b).to match(/Refreshing all keys from the keyring of list #{list1.email} resulted in this:\n\n/)
      expect(b).to match(/\nThis key was updated \(new signatures\):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo \d{4}-\d{2}-\d{2} \[expired: \d{4}-\d{2}-\d{2}\]\n/)
      expect(b).to match(/\nThis key was updated \(new user-IDs and new signatures\):\n0x6EE51D78FD0B33DE65CCF69D2104E20E20889F66 new@example.org \d{4}-\d{2}-\d{2}\n/)

      teardown_list_and_mailer(list1)
      teardown_list_and_mailer(list2)
    end

    it 'reports errors from refreshing keys' do
      list = create(:list)
      list.subscribe("admin@example.org", nil, true)
      list.import_key(File.read("spec/fixtures/expired_key.txt"))

      Cli.new.refresh_keys
      mail = Mail::TestMailer.deliveries.find { |message| message.to == [list.admins.first.email] }

      expect(mail.first_plaintext_part.decoded).to include("Refreshing all keys from the keyring of list #{list.email} resulted in this")
      if GPGME::Ctx.sufficient_gpg_version?('2.1')
        expect(mail.first_plaintext_part.decoded).to include("keyserver refresh failed:")
      else
        # The wording differs slightly among versions.
        expect(mail.first_plaintext_part.decoded).to match(/gpgkeys: .* error .* connect/)
      end

      teardown_list_and_mailer(list)
    end

    it "warns about file system permissions if it was run as root" do
      expect(Process).to receive(:euid).and_return(0)
      list = create(:list)

      orig_stdout = $stdout
      $stdout = StringIO.new
      Cli.new.refresh_keys(list.email)
      output = $stdout.string
      $stdout = orig_stdout

      expect(output).to include("Warning: this process was run as root")
    end
  end

  context '#pin_keys' do
    it 'pins fingerprints on not yet set keys' do
      list = create(:list)
      list.subscribe("admin@example.org", nil, true)
      list.subscribe("schleuder2@example.org", nil, false)
      list.import_key(File.read('spec/fixtures/example_key.txt'))
      expect(list.subscriptions_without_fingerprint.size).to eq 2

      Cli.new.pin_keys

      expect(list.subscriptions_without_fingerprint.size).to eq 1
      expect(list.subscriptions_without_fingerprint.collect(&:email)).to eq ['admin@example.org']

      mail = Mail::TestMailer.deliveries.first

      expect(Mail::TestMailer.deliveries.length).to eq 1
      expect(mail.first_plaintext_part.body.to_s).to eql("While checking all subscriptions of list #{list.email} we were pinning a matching key for the following subscriptions:\n\nschleuder2@example.org: C4D60F8833789C7CAA44496FD3FFA6613AB10ECE")

      teardown_list_and_mailer(list)
    end
    it 'only works on the specific list' do
      list1 = create(:list)
      list2 = create(:list)
      [list1,list2].each do |list|
        list.subscribe("admin@example.org", nil, true)
        list.subscribe("schleuder2@example.org", nil, false)
        list.import_key(File.read('spec/fixtures/example_key.txt'))
        expect(list.subscriptions_without_fingerprint.size).to eq 2
      end

      Cli.new.pin_keys list1.email

      expect(list1.subscriptions_without_fingerprint.size).to eq 1
      expect(list1.subscriptions_without_fingerprint.collect(&:email)).to eq ['admin@example.org']
      expect(list2.subscriptions_without_fingerprint.size).to eq 2

      mail = Mail::TestMailer.deliveries.first

      expect(Mail::TestMailer.deliveries.length).to eq 1
      expect(mail.first_plaintext_part.body.to_s).to eql("While checking all subscriptions of list #{list1.email} we were pinning a matching key for the following subscriptions:\n\nschleuder2@example.org: C4D60F8833789C7CAA44496FD3FFA6613AB10ECE")

      teardown_list_and_mailer(list1)
      teardown_list_and_mailer(list2)
    end

    it 'does not report anything if nothing was done' do
      list = create(:list)
      list.subscribe("admin@example.org", nil, true)
      list.subscribe("schleuder2@example.org", nil, false)
      expect(list.subscriptions_without_fingerprint.size).to eq 2

      Cli.new.pin_keys

      expect(list.subscriptions_without_fingerprint.size).to eq 2
      expect(Mail::TestMailer.deliveries.empty?).to eq true

      teardown_list_and_mailer(list)
    end
  end

  context '#install' do
    it 'exits if a shell-process failed' do
      dbfile = Conf.database["database"]
      tmp_filename = "#{dbfile}.tmp"
      File.rename(dbfile, tmp_filename)
      FileUtils.touch dbfile
      begin
        Cli.new.install
      rescue SystemExit => exc
      end

      expect(exc).to be_present
      expect(exc.status).to eql(1)
      File.rename(tmp_filename, dbfile)
    end

    it "warns about file system permissions if it was run as root" do
      expect(Process).to receive(:euid).and_return(0)

      orig_stdout = $stdout
      $stdout = StringIO.new
      Cli.new.install
      output = $stdout.string
      $stdout = orig_stdout

      expect(output).to include("Warning: this process was run as root")
    end
  end

  context '#commands' do
    it 'exits with a status code of 1 in case the command is not implemented' do
      run_cli('not-implemented')

      expect($?.exitstatus).to eq(1)
    end
  end

  context '#check_keys' do
    it "warns about file system permissions if it was run as root" do
      expect(Process).to receive(:euid).and_return(0)

      orig_stdout = $stdout
      $stdout = StringIO.new
      Cli.new.check_keys
      output = $stdout.string
      $stdout = orig_stdout

      expect(output).to include("Warning: this process was run as root")
    end
  end
end
