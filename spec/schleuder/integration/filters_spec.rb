require "spec_helper"

describe "running filters" do
  context '.max_message_size' do
    it "bounces to big mails" do
      list = create(:list)
      list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
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
      mail.body = '+' * (1024 * list.max_message_size_kb)
      mail.deliver

      big_email = Mail::TestMailer.deliveries.first
      Mail::TestMailer.deliveries.clear

      output = process_mail(big_email.to_s, list.email)
      expect(output.message).to include(I18n.t('errors.message_too_big', allowed_size: list.max_message_size_kb))

      teardown_list_and_mailer(list)
    end
  end
  context '.fix_exchange_messages!' do
    it "accepts an invalid pgp/mime Exchange message" do
      list = create(:list)
      list.subscribe("admin@example.org", nil, true)
      # so we can easily parse the outgoing mail
      list.send_encrypted_only = false
      list.save

      start_smtp_daemon
      message_path = 'spec/fixtures/mails/exchange.eml'

      error = run_schleuder(:work, list.email, message_path)
      mails = Dir.glob("#{smtp_daemon_outputdir}/mail-*")

      expect(error).to be_empty
      expect(mails.size).to eq 1

      exchange = Mail.read(mails.first)

      expect(exchange.to).to eql(["admin@example.org"])
      expect(exchange.parts.first.parts.last.decoded).to include("foo\n")

      stop_smtp_daemon
    end
    it "accepts a valid plain-text message" do
      list = create(:list)
      list.subscribe("admin@example.org", nil, true)
      # so we can easily parse the outgoing mail
      list.send_encrypted_only = false
      list.save

      start_smtp_daemon
      message_path = 'spec/fixtures/mails/exchange_no_parts.eml'

      error = run_schleuder(:work, list.email, message_path)
      mails = Dir.glob("#{smtp_daemon_outputdir}/mail-*")

      expect(error).to be_empty
      expect(mails.size).to eq 1

      exchange = Mail.read(mails.first)

      expect(exchange.to).to eql(["admin@example.org"])
      expect(exchange.parts.first.parts.last.decoded).to include("bla-vla")

      stop_smtp_daemon
    end
  end

  context '.strip_html_from_alternative!' do
    it "strips HTML-part from multipart/alternative-message that contains ascii-armored PGP-data" do
      list = create(:list)
      list.subscribe("admin@example.org", nil, true)
      # so we can easily parse the outgoing mail
      list.send_encrypted_only = false
      list.save

      start_smtp_daemon

      mail = Mail.new
      mail.to = list.email
      mail.from = 'outside@example.org'
      content = encrypt_string(list, "blabla")
      mail.text_part = content
      mail.html_part = "<p>#{content}</p>"
      mail.subject = "test"

      error = nil
      with_tmpfile(mail.to_s) do |fn|
        error = run_schleuder(:work, list.email, fn)
      end
      mails = Dir.glob("#{smtp_daemon_outputdir}/mail-*")

      expect(error).to be_empty
      expect(mails.size).to eq 1

      htmlmail = Mail.read(mails.first)

      expect(htmlmail.to).to eql(["admin@example.org"])
      signed_parts = htmlmail.parts[0].parts
      expect(signed_parts[0].body.to_s).to include("Note: This message included an alternating HTML-part that contained\n  PGP-data. The HTML-part was removed to enable parsing the message more\n  properly.\n")
      # why is this double wrapped?
      expect(signed_parts[1].parts[0][:content_type].content_type).to eql("text/plain")
      expect(signed_parts[1].parts[0].body.to_s).to eql("blabla\n")

      stop_smtp_daemon
    end
    it "does NOT strip HTML-part from multipart/alternative-message that does NOT contain ascii-armored PGP-data" do
      list = create(:list)
      list.subscribe("admin@example.org", nil, true)
      # so we can easily parse the outgoing mail
      list.send_encrypted_only = false
      list.save

      start_smtp_daemon

      mail = Mail.new
      mail.to = list.email
      mail.from = 'outside@example.org'
      content = "blabla"
      mail.text_part = content
      mail.html_part = "<p>#{content}</p>"
      mail.subject = "test"

      error = nil
      with_tmpfile(mail.to_s) do |fn|
        error = run_schleuder(:work, list.email, fn)
      end
      mails = Dir.glob("#{smtp_daemon_outputdir}/mail-*")

      expect(error).to be_empty
      expect(mails.size).to eq 1

      htmlmail = Mail.read(mails.first)

      expect(htmlmail.to).to eql(["admin@example.org"])
      # this is double wrapped
      signed_parts = htmlmail.parts[0].parts[1].parts
      expect(signed_parts[0][:content_type].content_type).to eql("text/plain")
      expect(signed_parts[0].body.to_s).to eql("blabla")
      expect(signed_parts[1][:content_type].content_type).to eql("text/html")
      expect(signed_parts[1].body.to_s).to eql("<p>blabla</p>")

      stop_smtp_daemon
    end
  end
end
