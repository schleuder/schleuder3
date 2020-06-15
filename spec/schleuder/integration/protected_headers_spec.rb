require "spec_helper"

describe "protected subject" do
  it "is not leaked" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    mail = Mail.read("spec/fixtures/mails/protected-headers.eml")
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first

    expect(raw.subject).to eql('Encrypted Message')

    teardown_list_and_mailer(list)
  end

  it "is included in mime-headers" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    mail = Mail.read("spec/fixtures/mails/protected-headers.eml")
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(raw.to_s).not_to match('Re: the real subject')
    expect(message.subject).to eql("Re: the real subject")
    expect(message.content_type_parameters['protected-headers']).to eql("v1")

    teardown_list_and_mailer(list)
  end

  it "is included as mime-part in body" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    mail = Mail.read("spec/fixtures/mails/protected-headers.eml")
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.parts[1].body.to_s).to eql("Subject: Re: the real subject\n")

    teardown_list_and_mailer(list)
  end

  it "don't block request-messages" do
    list = create(:list, email: 'something@example.org')
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    mail = Mail.read("spec/fixtures/mails/protected-headers-request.eml")
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.body.to_s).to include('59C71FB38AEE22E091C78259D06350440F759BD3')

    teardown_list_and_mailer(list)
  end

  it "works with mutt protected headers" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    mail = Mail.read("spec/fixtures/mails/mutt_protected_headers.txt")
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.parts[1].body.to_s).to eql("Subject: x\n")
    expect(message.parts[2].body.to_s).to eql("test\n")

    teardown_list_and_mailer(list)
  end

  it "recognizes keywords in mails with protected headers and empty subject" do
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
    mail.body = "x-list-name: #{list.email}\nx-list-keys"
    protected_headers = Mail::Part.new do
      body "Subject: protected"
      content_type "text/rfc822-headers; protected-headers=v1"
    end
    mail.add_part protected_headers
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    
    expect(message.first_plaintext_part.body.to_s).to include("59C71FB38AEE22E091C78259D06350440F759BD3")
    expect(message.first_plaintext_part.body.to_s).to_not include("Your message didn't contain any keywords, thus there was nothing to do.")

    teardown_list_and_mailer(list)
  end

end
