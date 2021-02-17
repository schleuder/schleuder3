require 'spec_helper'

describe Schleuder::Runner do
  describe '#run' do
    context 'with a plain text message' do
      it 'delivers the incoming message' do
        list = create(:list, send_encrypted_only: false)
        list.subscribe('admin@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/plain/thunderbird.eml')

        error = Schleuder::Runner.new().run(mail, list.email)

        expect(Mail::TestMailer.deliveries.length).to eq 1
        expect(error).to be_blank

        teardown_list_and_mailer(list)
      end

      it 'has the correct headerlines' do
        list = create(:list, send_encrypted_only: false)
        list.subscribe('admin@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/plain/thunderbird.eml')

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.to).to eq ['admin@example.org']
        expect(message.header.to_s.scan('admin@example.org').size).to eq 1
        expect(message.from).to eq [list.email]

        teardown_list_and_mailer(list)
      end

      it 'contains the specified pseudoheaders in the correct order' do
        list = create(:list, send_encrypted_only: false, headers_to_meta: ['from', 'sig'])
        list.subscribe('admin@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/plain/thunderbird.eml')

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first
        content_part = message.parts.first
        separator = '------------------------------------------------------------------------------'
        pseudoheaders = "From: Nina Siessegger <schleuder@example.org>\nSig: Unsigned\n#{separator}\n"

        expect(content_part.parts.first.body).to include(pseudoheaders)
        expect(content_part.parts.first.body).not_to include('To:')
        expect(content_part.parts.first.body).not_to include('Enc:')
        expect(content_part.parts.first.body).not_to include('Date:')

        teardown_list_and_mailer(list)
      end

      it "doesn't have unwanted headerlines from the original message" do
        list = create(:list, send_encrypted_only: false)
        list.subscribe('admin@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/plain/thunderbird.eml')

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.to).to eq ['admin@example.org']
        expect(message.header.to_s.scan('zeromail').size).to eq 0
        expect(message.header.to_s.scan('nna.local').size).to eq 0
        expect(message.header.to_s.scan('80.187.107.60').size).to eq 0
        expect(message.header.to_s.scan('User-Agent:').size).to eq 0

        teardown_list_and_mailer(list)
      end

      it "doesn't leak the Message-Id as configured" do
        list = create(:list, send_encrypted_only: false, keep_msgid: false)
        list.subscribe('admin@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/plain/thunderbird.eml')

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.header.to_s.scan('8db04406-e2ab-fd06-d4c5-c19b5765c52b@web.de').size).to eq 0

        teardown_list_and_mailer(list)
      end

      it 'does keep the Message-Id as configured' do
        list = create(:list, send_encrypted_only: false, keep_msgid: true)
        list.subscribe('admin@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/plain/thunderbird.eml')

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.header.to_s.scan('8db04406-e2ab-fd06-d4c5-c19b5765c52b@web.de').size).to eq 1

        teardown_list_and_mailer(list)
      end

      it 'contains the Autocrypt header if include_autocrypt_header is set to true' do
        list = create(
          :list,
          send_encrypted_only: false,
          include_autocrypt_header: true,
        )
        list.subscribe('admin@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/plain/thunderbird.eml')
        
        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        keydata = list.key_minimal_base64_encoded.gsub(/(.{78})/, '\1 ')
        expect(message.header['Autocrypt'].to_s).to eq("addr=#{list.email}; prefer-encrypt=mutual; keydata=#{keydata}")
        
        teardown_list_and_mailer(list)
      end
      
      it 'does not contain the Autocrypt header if include_autocrypt_header is set to false' do
        list = create(
          :list,
          send_encrypted_only: false,
          include_autocrypt_header: false,
        )
        list.subscribe('admin@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/plain/thunderbird.eml')
        
        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first
        
        expect(message.header.to_s).to_not include('Autocrypt')
        
        teardown_list_and_mailer(list)
      end

      it 'contains the list headers if include_list_headers is set to true' do
        list = create(
          :list,
          email: 'superlist@example.org',
          send_encrypted_only: false,
          include_list_headers: true,
        )
        list.subscribe('admin@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/plain/thunderbird.eml')

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.header['List-Id'].to_s).to eq '<superlist.example.org>'
        expect(message.header['List-Owner'].to_s).to eq "<mailto:superlist-owner@example.org> (Use list's public key)"
        expect(message.header['List-Help'].to_s).to eq '<https://schleuder.org/>'

        teardown_list_and_mailer(list)
      end

      it 'contains the open pgp header if include_openpgp_header is set to true' do
        list = create(
          :list,
          send_encrypted_only: false,
          include_openpgp_header: true,
        )
        list.subscribe('admin@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/plain/thunderbird.eml')

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.header['Openpgp'].to_s).to include list.fingerprint

        teardown_list_and_mailer(list)
      end

      it 'does not deliver content if send_encrypted_only is set to true' do
        list = create(:list, send_encrypted_only: true)
        list.subscribe('admin@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/plain/thunderbird.eml')

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.body).to eq ''
        expect(message.parts.first.body.to_s).to include 'You missed an email from '\
          "#{list.email} because your subscription isn't associated with a "\
          '(usable) OpenPGP key. Please fix this.'

        teardown_list_and_mailer(list)
      end

      it 'includes the internal_footer' do
        list = create(
          :list, 
          send_encrypted_only: false,
          internal_footer: "-- \nfor our eyes only!"
        )
        list.subscribe('admin@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/plain/thunderbird.eml')

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.parts.first.parts.last.body.to_s).to eql(list.internal_footer)

        teardown_list_and_mailer(list)
      end

      it 'does not include the public_footer' do
        public_footer = "-- \nsomething public blabla"
        list = create(
          :list,
          send_encrypted_only: false,
          internal_footer: "-- \nfor our eyes only!",
          public_footer: public_footer
        )
        list.subscribe('admin@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/plain/thunderbird.eml')

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.parts.first.to_s).not_to include(list.public_footer)

        teardown_list_and_mailer(list)
      end
    end

    context 'mails not encrypted to the list key' do
      it 'handles a mail which was encrypted to an absent key and returns DecryptionFailed error' do
        list = create(
          :list,
          send_encrypted_only: false
        )
        list.subscribe('schleuder@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/encrypted-to-absent-key.txt')

        result = Schleuder::Runner.new().run(mail, list.email)


        expect(result.class).to eql(Schleuder::Errors::DecryptionFailed)

        teardown_list_and_mailer(list)
      end

      it 'handles a mail which was encrypted to a passphrase and returns DecryptionFailed error' do
        list = create(
          :list,
          send_encrypted_only: false
        )
        list.subscribe('schleuder@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/encrypted-to-passphrase.txt')

        result = Schleuder::Runner.new().run(mail, list.email)
        
        expect(result.class).to eql(Schleuder::Errors::DecryptionFailed)

        teardown_list_and_mailer(list)
      end

      it 'handles a mail containing PGP-garbage and returns DecryptionFailed error' do
        list = create(
          :list,
          send_encrypted_only: false
        )
        list.subscribe('schleuder@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/containing-pgp-garbage.txt')

        result = Schleuder::Runner.new().run(mail, list.email)

        expect(result.class).to eql(Schleuder::Errors::DecryptionFailed)

        teardown_list_and_mailer(list)
      end
    end

    it "delivers a signed error message if a subscription's key is expired on a encrypted-only list" do
        list = create(:list, send_encrypted_only: true)
        list.subscribe('admin@example.org', nil, true, false)
        list.subscribe('expired@example.org', '98769E8A1091F36BD88403ECF71A3F8412D83889')
        key = File.read('spec/fixtures/expired_key.txt')
        list.import_key(key)
        mail = File.read('spec/fixtures/mails/plain/thunderbird.eml')

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first
        verified = message.verify
        signature_fingerprints = verified.signatures.map(&:fpr)

        expect(Mail::TestMailer.deliveries.size).to eq 1
        expect(message.to).to include('expired@example.org')
        expect(message.first_plaintext_part.decoded).to include('You missed an email from ')
        expect(signature_fingerprints).to eq([list.fingerprint])

        teardown_list_and_mailer(list)
    end

    it "delivers a signed error message if a subscription's key is not available on a encrypted-only list" do
        list = create(:list, send_encrypted_only: true)
        list.subscribe('admin@example.org', 'AAAAAAAABBBBBBBBBCCCCCCCCCDDDDDDDDEEEEEE', true)
        mail = File.read('spec/fixtures/mails/plain/thunderbird.eml')

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.to).to eq ['admin@example.org']
        expect(message.first_plaintext_part.decoded).to include("You missed an email from #{list.email} ")

        teardown_list_and_mailer(list)
    end

    it 'injects pseudoheaders appropriately into an unsigned thunderbird-multipart/alternative-message' do
      list = create(:list, send_encrypted_only: false)
      list.subscribe('admin@example.org', nil, true)
      mail = File.read('spec/fixtures/mails/multipart-alternative/thunderbird-multi-alt-unsigned.eml')

      Schleuder::Runner.new().run(mail, list.email)
      message = Mail::TestMailer.deliveries.first
      content_part = message.parts.first

      expect(message.to).to eq ['admin@example.org']
      expect(content_part.mime_type).to eql('multipart/mixed')
      expect(content_part.body).to be_blank
      expect(content_part.parts.size).to eql(2)
      expect(content_part.parts.first.mime_type).to eql('text/plain')
      expect(content_part.parts.first.body).to include('From: paz <paz@nadir.org>')
      expect(content_part.parts.last.mime_type).to eql('multipart/alternative')

      teardown_list_and_mailer(list)
    end

    it 'injects pseudoheaders appropriately into a signed multipart/alternative-message (thunderbird+enigmail-1.9) ' do
      list = create(:list, send_encrypted_only: false)
      list.subscribe('admin@example.org', nil, true)
      mail = File.read('spec/fixtures/mails/multipart-alternative/thunderbird-multi-alt-signed.eml')

      Schleuder::Runner.new().run(mail, list.email)
      message = Mail::TestMailer.deliveries.first
      content_part = message.parts.first

      expect(message.to).to eq ['admin@example.org']
      expect(content_part.mime_type).to eql('multipart/mixed')
      expect(content_part.body).to be_blank
      expect(content_part.parts.size).to eql(2)
      expect(content_part.parts.first.mime_type).to eql('text/plain')
      expect(content_part.parts.first.body).to include('From: paz <paz@nadir.org>')
      expect(content_part.parts.last.mime_type).to eql('multipart/mixed')
      expect(content_part.parts.last.parts.size).to eql(1)
      expect(content_part.parts.last.parts.first.mime_type).to eql('multipart/alternative')

      teardown_list_and_mailer(list)
    end

    context 'Quoted-Printable encoding' do
      it 'is handled properly in cleartext emails' do
        list = create(:list, send_encrypted_only: false)
        list.subscribe('admin@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/qp-encoding-clear.eml')

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first
        content_part = message.parts.first

        if content_part.parts.last.content_transfer_encoding == 'quoted-printable'
          expect(content_part.parts.last.encoded).to include('bug=3D86')
          expect(content_part.parts.last.encoded).not_to include('bug=86')
          expect(content_part.parts.last.decoded).to include('bug=86')
        else
          expect(content_part.parts.last.encoded).not_to include('bug=3D86')
          expect(content_part.parts.last.decoded).to include('bug=86')
        end

        teardown_list_and_mailer(list)
      end

      it 'is handled properly in encrypted+signed emails' do
        list = create(:list, send_encrypted_only: false)
        list.subscribe('admin@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
        mail = File.read('spec/fixtures/mails/qp-encoding-encrypted+signed.eml')

        Schleuder::Runner.new().run(mail, list.email)
        raw = Mail::TestMailer.deliveries.first
        message = Mail.create_message_to_list(raw.to_s, list.email, list).setup
        content_part = message.parts.last.first_plaintext_part

        expect(content_part.decoded).to include('bug=86')

        teardown_list_and_mailer(list)
      end

      it 'is handled properly in encrypted emails' do
        list = create(:list, send_encrypted_only: false)
        list.subscribe('admin@example.org', nil, true)
        mail = File.read('spec/fixtures/mails/qp-encoding-encrypted.eml')

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first
        content_part = message.parts.first

        if content_part.parts.last.content_transfer_encoding == 'quoted-printable'
          expect(content_part.parts.last.encoded).to include('bug=3D86')
          expect(content_part.parts.last.encoded).not_to include('bug=86')
          expect(content_part.parts.last.decoded).to include('bug=86')
        else
          expect(content_part.parts.last.encoded).not_to include('bug=3D86')
          expect(content_part.parts.last.decoded).to include('bug=86')
        end

        teardown_list_and_mailer(list)
      end
    end

    it 'does not throw an error on emails with large first mime-part' do
      list = create(:list)
      list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
      ENV['GNUPGHOME'] = list.listdir
      mail = Mail.new
      mail.to = list.request_address
      mail.from = list.admins.first.email
      gpg_opts = {
        encrypt: true,
        keys: {list.request_address => list.fingerprint},
        sign: true,
        sign_as: list.admins.first.fingerprint
      }
      mail.gpg(gpg_opts)
      mail.body = File.read('spec/fixtures/mails/big_first_mime_part.txt')
      mail.deliver

      message = Mail::TestMailer.deliveries.first
      Mail::TestMailer.deliveries.clear

      output = process_mail(message.to_s, list.email)
      expect(output).to be nil

      teardown_list_and_mailer(list)
    end

    it 'does not throw an error on emails that contain other gpg keywords' do
      list = create(:list)
      list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
      ENV['GNUPGHOME'] = list.listdir
      mail = Mail.new
      mail.to = list.request_address
      mail.from = list.admins.first.email
      gpg_opts = {
        encrypt: true,
        keys: {list.request_address => list.fingerprint},
        sign: true,
        sign_as: list.admins.first.fingerprint
      }
      mail.gpg(gpg_opts)
      mail.body = File.read('spec/fixtures/mails/mail_with_pgp_boundaries_in_body.txt')
      mail.deliver

      message = Mail::TestMailer.deliveries.first
      Mail::TestMailer.deliveries.clear

      output = process_mail(message.to_s, list.email)
      expect(output).to be nil

      teardown_list_and_mailer(list)
    end
    it 'does not throw an error on emails with an attached pgp key as application/octet-stream' do
      list = create(:list)
      list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
      ENV['GNUPGHOME'] = list.listdir
      mail = Mail.new
      mail.to = list.request_address
      mail.from = list.admins.first.email
      gpg_opts = {
        encrypt: true,
        keys: {list.request_address => list.fingerprint},
        sign: true,
        sign_as: list.admins.first.fingerprint
      }
      mail.gpg(gpg_opts)
      mail.body = 'See attachment'
      mail.attachments['251F2412.asc'] = {
        :content_type => '"application/octet-stream"; name="251F2412.asc"',
        :content_transfer_encoding => '7bit',
        :content => File.read('spec/fixtures/bla_foo_key.txt')
      }
      mail.deliver

      message = Mail::TestMailer.deliveries.first
      Mail::TestMailer.deliveries.clear

      output = process_mail(message.to_s, list.email)
      expect(output).to be nil

      teardown_list_and_mailer(list)
    end
    it 'does not throw an error on encrypted but unsigned emails that contain a forwarded encrypted email' do
      list = create(:list)
      list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
      ENV['GNUPGHOME'] = list.listdir
      mail = Mail.new
      mail.to = list.request_address
      mail.from = list.admins.first.email
      gpg_opts = {
        encrypt: true,
        keys: {list.request_address => list.fingerprint},
        sign: false,
      }
      mail.gpg(gpg_opts)
      mail.body = "Hi\n\nI'll forward you this email, have a look at it!\n\n#{File.read('spec/fixtures/mails/encrypted-mime/thunderbird.eml')}"
      mail.deliver

      message = Mail::TestMailer.deliveries.first
      Mail::TestMailer.deliveries.clear

      output = process_mail(message.to_s, list.email)
      expect(output).to be nil

      teardown_list_and_mailer(list)
    end

    it 'does not throw an error on emails with broken utf-8' do
      list = create(:list, send_encrypted_only: false)
      list.subscribe('admin@example.org', nil, true)
      mail = File.read('spec/fixtures/mails/broken_utf8_charset.eml')

      # From mail 2.7.0 this is handled correctly
      # See #334 for background
      if Gem::Version.new(Mail::VERSION.version) < Gem::Version.new('2.7.0')
        expect{
          Schleuder::Runner.new().run(mail, list.email)
        }.to raise_error(ArgumentError)
      else
        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        output = process_mail(message.to_s, list.email)
        expect(output).to be nil
      end

      teardown_list_and_mailer(list)
    end
  end
  context 'after keyword parsing' do
    it 'falls back to default charset per RFC if none is set' do
      list = create(:list, send_encrypted_only: false)
      list.subscribe('admin@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)

      # manually build a specific mail structure that comes without a charset
      mail = Mail.new
      mail.from = 'admin@example.org'
      mail.to = list.request_address
      ENV['GNUPGHOME'] = list.listdir
      cipher_data = GPGME::Data.new
      GPGME::Ctx.new({armor: true}) do |ctx|
        ctx.add_signer(*GPGME::Key.find(:secret, '59C71FB38AEE22E091C78259D06350440F759BD3', :sign))
        ctx.encrypt_sign(
          GPGME::Key.find(:public, list.fingerprint, :encrypt),
          GPGME::Data.new("Content-Type: text/plain\n\nNur ein test\n"),
          cipher_data, 0
        )
        cipher_data.seek(0)
      end

      mail.content_type "multipart/encrypted; boundary=\"#{mail.boundary}\"; protocol=\"application/pgp-encrypted\""
      ver_part = Mail::Part.new do
        body 'Version: 1'
        content_type 'application/pgp-encrypted'
      end
      mail.add_part ver_part
      enc_part = Mail::Part.new do
        body cipher_data.to_s
        content_type 'application/octet-stream'
      end
      mail.add_part enc_part
      output = process_mail(mail.to_s, list.email)
      expect(output).to be nil

      teardown_list_and_mailer(list)
    end

    it 'falling back works also with non-ascii content' do
      list = create(:list, send_encrypted_only: false)
      list.subscribe('admin@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)

      # manually build a specific mail structure that comes without a charset
      mail = Mail.new
      mail.from = 'admin@example.org'
      mail.to = list.request_address
      ENV['GNUPGHOME'] = list.listdir
      cipher_data = GPGME::Data.new
      GPGME::Ctx.new({armor: true}) do |ctx|
        ctx.add_signer(*GPGME::Key.find(:secret, '59C71FB38AEE22E091C78259D06350440F759BD3', :sign))
        ctx.encrypt_sign(
          GPGME::Key.find(:public, list.fingerprint, :encrypt),
          GPGME::Data.new("Content-Type: text/plain\n\nNür ein test\n"),
          cipher_data, 0
        )
        cipher_data.seek(0)
      end

      mail.content_type "multipart/encrypted; boundary=\"#{mail.boundary}\"; protocol=\"application/pgp-encrypted\""
      ver_part = Mail::Part.new do
        body 'Version: 1'
        content_type 'application/pgp-encrypted'
      end
      mail.add_part ver_part
      enc_part = Mail::Part.new do
        body cipher_data.to_s
        content_type 'application/octet-stream'
      end
      mail.add_part enc_part
      output = process_mail(mail.to_s, list.email)
      expect(output).to be nil

      teardown_list_and_mailer(list)
    end
  end

end
