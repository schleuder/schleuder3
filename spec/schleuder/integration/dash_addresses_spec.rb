require 'spec_helper'

describe 'someone sends an email to a listname-dash-address' do
  it "sends the list's key as reply to -sendkey" do
    list = create(:list)
    list.subscribe('schleuder@example.org', nil, true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.sendkey_address
    mail.from = 'outside@example.org'
    mail.body = 'The key, please!'
    mail.subject = 'key'
    mail.deliver

    mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    output = process_mail(mail.to_s, list.sendkey_address)
    expect(output).to be_nil

    message = Mail::TestMailer.deliveries.first

    expect(message.to).to eql(['outside@example.org'])
    signed_message_parts = message.parts[0].parts
    expect(signed_message_parts.first.body.to_s).to eql('Find the key for this address attached.')
    expect(message.parts[0].attachments.first.body.to_s).to include(list.fingerprint)
    expect(message.parts[0].attachments.first.body.to_s).to include('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(message.in_reply_to).to eql(mail.message_id)
  end

  it 'forwards the message to the admins if extension is -owner' do
    list = create(:list)
    # owner needs a key so they get email
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.subscribe('admin@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.owner_address
    mail.from = 'outside@example.org'
    mail.body = 'Please contact me directly!'
    mail.subject = 'help'
    mail.deliver

    mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    output = process_mail(mail.to_s, list.owner_address)
    expect(output).to be_nil

    raw_msgs = Mail::TestMailer.deliveries
    raw_msgs.sort_by { |msg| msg.to.first }
    # reparse the messages so we decrypt and remove all the craft
    # for easier parsing afterwards
    message1, message2 = raw_msgs[0..1].collect{|m|
      Mail.create_message_to_list(m.to_s, list.email, list).setup
    }

    expect(message1.to).to eql(['admin@example.org'])
    expect(message1.subject).to eql('help')
    expect(message1.parts.first.body.to_s).to include('From: outside@example.org')
    expect(message1.parts.first.body.to_s).to include('Note: The following message was received for the list-owners.')
    expect(message1.parts.last.body.to_s).to eql('Please contact me directly!')

    expect(message2.to).to eql(['schleuder@example.org'])
    expect(message2.subject).to eql('help')
    expect(message2.parts.first.body.to_s).to include('From: outside@example.org')
    expect(message2.parts.first.body.to_s).to include('Note: The following message was received for the list-owners.')
    expect(message2.parts.last.body.to_s).to eql('Please contact me directly!')
  end

  it 'forwards the message to the admins if extension is -bounce' do
    list = create(:list)
    list.subscribe('admin@example.org', nil, true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.bounce_address
    mail.from = 'mailer-daemon@example.org'
    mail.body = 'delivery failure'
    mail.subject = 'something'
    mail.deliver

    mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    output = process_mail(mail.to_s, list.bounce_address)
    expect(output).to be_nil

    message = Mail::TestMailer.deliveries.first

    expect(message.to).to eql(['admin@example.org'])
    expect(message.subject).to eql(I18n.t('automated_message_subject'))
    signed_message_parts = message.parts[0].parts
    expect(signed_message_parts.first.body.to_s).to eql(I18n.t('forward_automated_message_to_admins'))
    expect(signed_message_parts.last.mime_type).to eql('message/rfc822')
    expect(signed_message_parts.last.body.to_s).to include('From: mailer-daemon@example.org')
    expect(signed_message_parts.last.body.to_s).to include(mail.message_id)
    expect(signed_message_parts.last.body.to_s).to include('Subject: something')
    expect(signed_message_parts.last.body.to_s).to include('delivery failure')
  end

  it "forwards the message to the admins if extension is -bounce and it's a real bounce mail" do
    list = create(:list)
    list.subscribe('admin@example.org', nil, true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new(File.read('spec/fixtures/mails/bounce.eml'))
    mail.to = list.owner_address
    mail.deliver

    mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    output = process_mail(mail.to_s, list.bounce_address)
    expect(output).to be_nil

    message = Mail::TestMailer.deliveries.first

    expect(message.to).to eql(['admin@example.org'])
    expect(message.subject).to eql(I18n.t('automated_message_subject'))
    signed_message_parts = message.parts[0].parts
    expect(signed_message_parts.first.body.to_s).to eql(I18n.t('forward_automated_message_to_admins'))
    expect(signed_message_parts.last.mime_type).to eql('message/rfc822')
    expect(signed_message_parts.last.body.to_s).to include('Mailer-Daemon@schleuder.example.org')
    expect(signed_message_parts.last.body.to_s).to include(mail.message_id)
    expect(signed_message_parts.last.body.to_s).to include('Subject: bounce test')
    expect(signed_message_parts.last.body.to_s).to include('mailbox is full')
  end
end

