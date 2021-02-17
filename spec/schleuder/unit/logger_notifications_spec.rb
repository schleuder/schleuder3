require 'spec_helper'

describe Schleuder::LoggerNotifications do
  context 'return path' do
    it 'sets default superadmin' do
      list = create(:list, send_encrypted_only: false)
      list.subscribe('schleuder@example.org', nil, true)
      list.logger.notify_admin('Something', nil, I18n.t('notice'))

      message = Mail::TestMailer.deliveries.first

      expect(message.sender).to eql('root@localhost')
      expect(message[:Errors_To].to_s).to eql('root@localhost')
    end

    it 'sets superadmin' do
      oldval = Conf.instance.config['superadmin']
      Conf.instance.config['superadmin'] = 'schleuder-admin@example.org'
      list = create(:list, send_encrypted_only: false)
      list.subscribe('schleuder@example.org', nil, true)
      list.logger.notify_admin('Something', nil, I18n.t('notice'))

      message = Mail::TestMailer.deliveries.first

      expect(message.sender).to eql('schleuder-admin@example.org')
      expect(message[:Errors_To].to_s).to eql('schleuder-admin@example.org')
      Conf.instance.config['superadmin'] = oldval
    end
  end
  it 'notifies admins of simple text-message' do
    list = create(:list, send_encrypted_only: false)
    list.subscribe('schleuder@example.org', nil, true)
    list.logger.notify_admin('Something', nil, I18n.t('notice'))

    message = Mail::TestMailer.deliveries.first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.subject).to eql(I18n.t('notice'))
    expect(message.first_plaintext_part.body.to_s).to eql('Something')
  end

  it 'notifies admins of multiple text-messages' do
    list = create(:list, send_encrypted_only: false)
    list.subscribe('schleuder@example.org', nil, true)
    list.logger.notify_admin(['Something', 'anotherthing'], nil, I18n.t('notice'))

    message = Mail::TestMailer.deliveries.first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.subject).to eql(I18n.t('notice'))
    expect(message.parts.first.parts.first.body.to_s).to eql('Something')
    expect(message.parts.first.parts.last.body.to_s).to eql('anotherthing')
  end

  it 'notifies admins of multiple text-messages and the original message' do
    list = create(:list, send_encrypted_only: false)
    list.subscribe('schleuder@example.org', nil, true)
    mail = Mail.new
    mail.subject = 'A subject'
    list.logger.notify_admin(['Something', 'anotherthing'], mail.to_s, I18n.t('notice'))

    message = Mail::TestMailer.deliveries.first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.subject).to eql(I18n.t('notice'))
    expect(message.parts.first.parts.first.body.to_s).to eql('Something')
    expect(message.parts.first.parts[1].body.to_s).to eql('anotherthing')
    expect(message.parts.first.parts[2].body.to_s).to include('Subject: A subject')
    expect(message.parts.first.parts[2][:content_type].content_type).to eql('message/rfc822')
  end

  it 'notifies admins encryptedly if their key is usable' do
    list = create(:list, send_encrypted_only: false)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    mail = Mail.new
    mail.subject = 'A subject'
    list.logger.notify_admin(['Something', 'anotherthing'], mail.to_s, I18n.t('notice'))

    message = Mail::TestMailer.deliveries.first

    expect(message.subject).to eql('Notice')
    expect(message.parts.size).to be(2)
    expect(message.parts.last.body.to_s).to include('-----BEGIN PGP MESSAGE-----')
  end

  it 'notifies admins in the clear if their key is unusable' do
    list = create(:list, send_encrypted_only: false)
    key_material = File.read('spec/fixtures/partially_expired_key.txt')
    list.subscribe('schleuder@example.org', nil, true, true, key_material)
    mail = Mail.new
    mail.subject = 'A subject'
    list.logger.notify_admin('Something', mail.to_s, I18n.t('notice'))

    message = Mail::TestMailer.deliveries.first

    expect(message.subject).to eql('Notice')
    expect(message.parts.size).to be(2)
    expect(message.parts.first.parts.first.body.to_s).to eql('Something')
  end

  it 'includes a List-Id header in notification mails sent to admins' do
    list = create(:list, send_encrypted_only: false)
    list.subscribe('schleuder@example.org', nil, true)

    mail = Mail.new
    list.logger.notify_admin('Something', mail.to_s, I18n.t('notice'))

    message = Mail::TestMailer.deliveries.first

    expect(message.header['List-Id'].to_s).to eql("<#{list.email.gsub('@', '.')}>")
  end
end
