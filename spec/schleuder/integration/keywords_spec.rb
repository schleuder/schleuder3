# coding: utf-8
require 'spec_helper'

describe 'user sends keyword' do
  it 'x-subscribe without attributes' do
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
    mail.body = "x-list-name: #{list.email}\nX-SUBSCRIBE: test@example.org\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('test@example.org has been subscribed')
    expect(message.to_s).to match(/Fingerprint:\s*$/)
    expect(message.to_s).to include('Admin? false')
    expect(message.to_s).to include('Email-delivery enabled? true')

    expect(subscription).to be_present
    expect(subscription.fingerprint).to be_blank
    expect(subscription.admin).to eql(false)
    expect(subscription.delivery_enabled).to eql(true)


    teardown_list_and_mailer(list)
  end

  it 'x-subscribe with attributes' do
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
    mail.body = "x-list-name: #{list.email}\nX-SUBSCRIBE: test@example.org 0x#{list.fingerprint} true false\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('test@example.org has been subscribed')
    expect(message.to_s).to match(/Fingerprint:\s+#{list.fingerprint}/)
    expect(message.to_s).to include('Admin? true')
    expect(message.to_s).to include('Email-delivery enabled? false')

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql(list.fingerprint)
    expect(subscription.admin).to eql(true)
    expect(subscription.delivery_enabled).to eql(false)

    teardown_list_and_mailer(list)
  end

  it 'x-subscribe with one attribute and spaces-separated fingerprint' do
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
    mail.body = "x-list-name: #{list.email}\nX-SUBSCRIBE: test@example.org 0x#{list.fingerprint.dup.insert(4, ' ')} true\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('test@example.org has been subscribed')
    expect(message.to_s).to match(/Fingerprint:\s+#{list.fingerprint}/)
    expect(message.to_s).to include('Admin? true')
    expect(message.to_s).to include('Email-delivery enabled? true')

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql(list.fingerprint)
    expect(subscription.admin).to eql(true)
    expect(subscription.delivery_enabled).to eql(true)

    teardown_list_and_mailer(list)
  end


  it 'x-subscribe without attributes, but with spaces-separated fingerprint' do
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
    mail.body = "x-list-name: #{list.email}\nX-SUBSCRIBE: test@example.org 0x#{list.fingerprint.dup.insert(4, ' ')}\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('test@example.org has been subscribed')
    expect(message.to_s).to match(/Fingerprint:\s+#{list.fingerprint}/)
    expect(message.to_s).to include('Admin? false')
    expect(message.to_s).to include('Email-delivery enabled? true')

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql(list.fingerprint)
    expect(subscription.admin).to eql(false)
    expect(subscription.delivery_enabled).to eql(true)

    teardown_list_and_mailer(list)
  end

  it 'x-subscribe with attributes and spaces-separated fingerprint' do
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
    mail.body = "x-list-name: #{list.email}\nX-SUBSCRIBE: test@example.org 0x#{list.fingerprint.dup.insert(4, ' ')} true false\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('test@example.org has been subscribed')
    expect(message.to_s).to match(/Fingerprint:\s+#{list.fingerprint}/)
    expect(message.to_s).to include('Admin? true')
    expect(message.to_s).to include('Email-delivery enabled? false')

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql(list.fingerprint)
    expect(subscription.admin).to eql(true)
    expect(subscription.delivery_enabled).to eql(false)

    teardown_list_and_mailer(list)
  end

  it "x-subscribe with attributes (first one 'false') and spaces-separated fingerprint" do
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
    mail.body = "x-list-name: #{list.email}\nX-SUBSCRIBE: test@example.org 0x#{list.fingerprint.dup.insert(4, ' ')} false false\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('test@example.org has been subscribed')
    expect(message.to_s).to match(/Fingerprint:\s+#{list.fingerprint}/)
    expect(message.to_s).to include('Admin? false')
    expect(message.to_s).to include('Email-delivery enabled? false')

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql(list.fingerprint)
    expect(subscription.admin).to eql(false)
    expect(subscription.delivery_enabled).to eql(false)

    teardown_list_and_mailer(list)
  end

  it "x-subscribe with attributes (last one 'true') and spaces-separated fingerprint" do
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
    mail.body = "x-list-name: #{list.email}\nX-SUBSCRIBE: test@example.org 0x#{list.fingerprint.dup.insert(4, ' ')} false true\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('test@example.org has been subscribed')
    expect(message.to_s).to match(/Fingerprint:\s+#{list.fingerprint}/)
    expect(message.to_s).to include('Admin? false')
    expect(message.to_s).to include('Email-delivery enabled? true')

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql(list.fingerprint)
    expect(subscription.admin).to eql(false)
    expect(subscription.delivery_enabled).to eql(true)

    teardown_list_and_mailer(list)
  end

  it 'x-subscribe without arguments' do
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
    mail.body = "x-list-name: #{list.email}\nX-SUBSCRIBE:\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).not_to include('translation missing')
    expect(message.first_plaintext_part.body.to_s).to eql(I18n.t('keyword_handlers.subscription_management.subscribe_requires_arguments'))

    expect(subscription).to be_blank

    teardown_list_and_mailer(list)
  end

  it 'x-unsubscribe without argument' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    list.subscribe('admin@example.org', 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.request_address
    mail.from = 'schleuder@example.org'
    gpg_opts = {
      encrypt: true,
      keys: {list.request_address => list.fingerprint},
      sign: true,
      sign_as: '59C71FB38AEE22E091C78259D06350440F759BD3'
    }
    mail.gpg(gpg_opts)
    mail.body = "x-list-name: #{list.email}\nX-UNSUBSCRIBE:\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('schleuder@example.org has been unsubscribed')

    expect(subscription).to be_blank

    teardown_list_and_mailer(list)
  end

  it 'x-unsubscribe with invalid argument' do
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
    mail.body = "x-list-name: #{list.email}\nX-UNSUBSCRIBE: test@example.org\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('test@example.org is not subscribed')

    teardown_list_and_mailer(list)
  end

  it 'x-unsubscribe' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.subscribe('test@example.org')
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
    mail.body = "x-list-name: #{list.email}\nX-UNSUBSCRIBE: test@example.org\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('test@example.org has been unsubscribed')

    expect(subscription).to be_blank

    teardown_list_and_mailer(list)
  end

  it "x-unsubscribe doesn't unsubscribe last admin" do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.subscribe('test@example.org')
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
    mail.body = "x-list-name: #{list.email}\nX-UNSUBSCRIBE: schleuder@example.org\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s).to eql(I18n.t('keyword_handlers.subscription_management.cannot_unsubscribe_last_admin', email: 'schleuder@example.org'))
    expect(list.subscriptions.size).to be(2)

    teardown_list_and_mailer(list)
  end

  it 'x-set-fingerprint with own email-address and valid fingerprint' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-list-name: #{list.email}\nX-set-fingerprint: schleuder@example.org C4D60F8833789C7CAA44496FD3FFA6613AB10ECE\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'schleuder@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('Fingerprint for schleuder@example.org set to C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')

    teardown_list_and_mailer(list)
  end


  it 'x-set-fingerprint with own email-address and valid, spaces-separated fingerprint' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-list-name: #{list.email}\nX-set-fingerprint: schleuder@example.org C4D6 0F88 3378 9C7C  AA44 496F D3FF A661 3AB1 0ECE\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'schleuder@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('Fingerprint for schleuder@example.org set to C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')

    teardown_list_and_mailer(list)
  end


  it 'x-set-fingerprint without email-address and with valid fingerprint' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-list-name: #{list.email}\nX-set-fingerprint: C4D60F8833789C7CAA44496FD3FFA6613AB10ECE\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'schleuder@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('Fingerprint for schleuder@example.org set to C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')

    teardown_list_and_mailer(list)
  end

  it 'x-set-fingerprint with other email-address and valid fingerprint' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.subscribe('test@example.org')
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-list-name: #{list.email}\nX-set-fingerprint: test@example.org C4D60F8833789C7CAA44496FD3FFA6613AB10ECE\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('Fingerprint for test@example.org set to C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')

    teardown_list_and_mailer(list)
  end

  it 'x-set-fingerprint with other email-address and valid fingerprint as non-admin' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3')
    list.subscribe('test@example.org', 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.request_address
    mail.from = 'schleuder@example.org'
    gpg_opts = {
      encrypt: true,
      keys: {list.request_address => list.fingerprint},
      sign: true,
      sign_as: '59C71FB38AEE22E091C78259D06350440F759BD3'
    }
    mail.gpg(gpg_opts)
    mail.body = "x-list-name: #{list.email}\nX-set-fingerprint: test@example.org 59C71FB38AEE22E091C78259D06350440F759BD3\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('Only admins may set fingerprints of subscriptions other than their own')

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')

    teardown_list_and_mailer(list)
  end

  it 'x-set-fingerprint with email-address but without fingerprint' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-list-name: #{list.email}\nX-set-fingerprint: schleuder@example.org \nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'schleuder@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s).to eql(I18n.t(
      'keyword_handlers.subscription_management.set_fingerprint_requires_valid_fingerprint',
      fingerprint: ''
    ))

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql('59C71FB38AEE22E091C78259D06350440F759BD3')

    teardown_list_and_mailer(list)
  end

  it 'x-set-fingerprint with email-address but without valid fingerprint' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-list-name: #{list.email}\nX-set-fingerprint: schleuder@example.org 59C71FB38AEE22E091C78259D0\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'schleuder@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s).to eql(I18n.t(
      'keyword_handlers.subscription_management.set_fingerprint_requires_valid_fingerprint',
      fingerprint: '59c71fb38aee22e091c78259d0'
    ))

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql('59C71FB38AEE22E091C78259D06350440F759BD3')

    teardown_list_and_mailer(list)
  end

  it 'x-set-fingerprint without email-address and with invalid fingerprint' do
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
    mail.body = "x-list-name: #{list.email}\nX-set-fingerprint: blabla\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'schleuder@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s).to eql(I18n.t(
      'keyword_handlers.subscription_management.set_fingerprint_requires_valid_fingerprint',
      fingerprint: 'blabla'
    ))

    expect(subscription.fingerprint).to eql('59C71FB38AEE22E091C78259D06350440F759BD3')

    teardown_list_and_mailer(list)
  end

  it 'x-set-fingerprint with not-subscribed email-address and valid fingerprint' do
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
    mail.body = "x-list-name: #{list.email}\nX-set-fingerprint: bla@example.org C4D60F8833789C7CAA44496FD3FFA6613AB10ECE\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('bla@example.org is not subscribed')

    teardown_list_and_mailer(list)
  end

  it 'x-set-fingerprint without argument' do
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
    mail.body = "x-list-name: #{list.email}\nX-set-fingerprint: \nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s).to eql(I18n.t('keyword_handlers.subscription_management.set_fingerprint_requires_arguments'))

    teardown_list_and_mailer(list)
  end

  it 'x-unset-fingerprint without argument' do
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
    mail.body = "x-list-name: #{list.email}\nX-unset-fingerprint: \nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s).to eql(I18n.t('keyword_handlers.subscription_management.unset_fingerprint_requires_arguments'))

    teardown_list_and_mailer(list)
  end

  it 'x-unset-fingerprint with other email-address as admin' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.subscribe('test@example.org','C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-list-name: #{list.email}\nX-unset-fingerprint: test@example.org\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('Fingerprint for test@example.org removed.')

    expect(subscription).to be_present
    expect(subscription.fingerprint.blank?).to be_truthy

    teardown_list_and_mailer(list)
  end
  it 'x-unset-fingerprint with own email-address as admin but without force' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-list-name: #{list.email}\nX-unset-fingerprint: schleuder@example.org\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'schleuder@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s).to eql(I18n.t('keyword_handlers.subscription_management.unset_fingerprint_requires_arguments'))

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql('59C71FB38AEE22E091C78259D06350440F759BD3')

    teardown_list_and_mailer(list)
  end
  it 'x-unset-fingerprint with own email-address as admin and force' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-list-name: #{list.email}\nX-unset-fingerprint: schleuder@example.org force\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'schleuder@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('Fingerprint for schleuder@example.org removed.')

    expect(subscription).to be_present
    expect(subscription.fingerprint.blank?).to be_truthy

    teardown_list_and_mailer(list)
  end
  it 'x-unset-fingerprint with not-subscribed email-address' do
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
    mail.body = "x-list-name: #{list.email}\nX-unset-fingerprint: bla@example.org\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('bla@example.org is not subscribed')

    teardown_list_and_mailer(list)
  end

  it 'x-unset-fingerprint with other email-address as non-admin' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3')
    list.subscribe('test@example.org', 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.request_address
    mail.from = 'schleuder@example.org'
    gpg_opts = {
      encrypt: true,
      keys: {list.request_address => list.fingerprint},
      sign: true,
      sign_as: '59C71FB38AEE22E091C78259D06350440F759BD3'
    }
    mail.gpg(gpg_opts)
    mail.body = "x-list-name: #{list.email}\nX-unset-fingerprint: test@example.org\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('Only admins may remove fingerprints of subscriptions other than their own')

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')

    teardown_list_and_mailer(list)
  end


  it 'x-list-subscriptions without arguments' do
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
    mail.body = "x-list-name: #{list.email}\nX-list-subscriptions\nx-stop:"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s.lines.size).to eql(3)
    expect(message.to_s).to include('schleuder@example.org	0x59C71FB38AEE22E091C78259D06350440F759BD3')

    teardown_list_and_mailer(list)
  end

  it 'x-list-subscriptions without arguments but with admin-notification' do
    list = create(:list, keywords_admin_notify: ['list-subscriptions'])
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.subscribe('user@example.org')
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
    mail.body = "x-list-name: #{list.email}\nX-list-subscriptions:\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    notification = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    raw = Mail::TestMailer.deliveries[1]
    response = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    expected_text = "Subscriptions:\n\nschleuder@example.org\t0x59C71FB38AEE22E091C78259D06350440F759BD3\nuser@example.org"

    expect(Mail::TestMailer.deliveries.size).to eql(2)
    expect(notification.to).to eql(['schleuder@example.org'])
    expect(notification.first_plaintext_part.body.to_s).to eql("schleuder@example.org sent this keyword:\n\nlist-subscriptions: \n\n\n...and received this response:\n\n#{expected_text}\n")


    expect(response.to).to eql(['schleuder@example.org'])
    expect(response.first_plaintext_part.body.to_s).to eql(expected_text)

    teardown_list_and_mailer(list)
  end

  it 'x-list-subscriptions with matching argument' do
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
    mail.body = "x-list-name: #{list.email}\nX-list-subscriptions: example.org\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s.lines.size).to eql(3)
    expect(message.to_s).to include('schleuder@example.org	0x59C71FB38AEE22E091C78259D06350440F759BD3')

    teardown_list_and_mailer(list)
  end

  it 'x-list-subscriptions with non-matching argument' do
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
    mail.body = "x-list-name: #{list.email}\nX-list-subscriptions: blabla\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s.lines.size).to eql(1)
    expect(message.to_s).to include('Your message resulted in no output')

    teardown_list_and_mailer(list)
  end

  it 'x-add-key with inline key-material' do
    list = create(:list, keywords_admin_notify: [])
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list_keys_num = list.keys.size
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
    keymaterial = File.read('spec/fixtures/example_key.txt')
    mail.body = "x-list-name: #{list.email}\nX-ADD-KEY:\nx-stop\n#{keymaterial}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num + 1)
    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s).to match(/^This key was newly added:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org \d{4}-\d{2}-\d{2}\n$/)

    teardown_list_and_mailer(list)
  end

  it 'x-add-key with an inline mix of key and non-key material' do
    list = create(:list, keywords_admin_notify: [])
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list_keys_num = list.keys.size
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
    keymaterial1 = File.read('spec/fixtures/example_key.txt')
    keymaterial2 = File.read('spec/fixtures/bla_foo_key.txt')
    mail.body = "x-list-name: #{list.email}\nX-ADD-KEY:\n#{keymaterial1}\nsome text\n#{keymaterial2}\n--\nthis is a signature"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num + 2)
    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s).to match(/^This key was newly added:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org \d{4}-\d{2}-\d{2}\n\n\nThis key was newly added:\n0x87E65ED2081AE3D16BE4F0A5EBDBE899251F2412 bla@foo \d{4}-\d{2}-\d{2}$/)

    teardown_list_and_mailer(list)
  end

  it 'x-add-key with attached key-material' do
    list = create(:list, keywords_admin_notify: [])
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list_keys_num = list.keys.size
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
    mail.body = "x-list-name: #{list.email}\nX-ADD-KEY:\nx-stop"
    mail.add_file('spec/fixtures/example_key.txt')
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num + 1)
    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s).to match(/^This key was newly added:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org \d{4}-\d{2}-\d{2}\n$/)

    teardown_list_and_mailer(list)
  end

  it 'x-add-key with attached quoted-printable key-material (as produced by Thunderbird)' do
    list = create(:list, keywords_admin_notify: [])
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list_keys_num = list.keys.size
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
    keywords = Mail::Part.new
    keywords.body = "\n\nx-list-name: #{list.email}\nX-ADD-KEY:"
    mail.parts << keywords
    mail.attachments['example_key.txt'] = {
      :content_type => '"application/pgp-keys"; name="example_key.txt"',
      :content_transfer_encoding => 'quoted-printable',
      :content => File.read('spec/fixtures/example_key.txt')
    }
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num + 1)
    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s).to match(/^This key was newly added:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org \d{4}-\d{2}-\d{2}\n$/)

    teardown_list_and_mailer(list)
  end

  it 'x-add-key to update a key' do
    list = create(:list, keywords_admin_notify: [])
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/expired_key.txt'))
    list_keys_num = list.keys.size
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
    mail.body = "x-list-name: #{list.email}\nX-ADD-KEY:\nx-stop"
    mail.add_file('spec/fixtures/expired_key_extended.txt')
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num)
    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s).to match(/^This key was updated:\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo \d{4}-\d{2}-\d{2} \[expired: \d{4}-\d{2}-\d{2}\]\n$/)

    teardown_list_and_mailer(list)
  end

  it 'x-add-key with garbage as key-material' do
    list = create(:list, keywords_admin_notify: [])
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list_keys_num = list.keys.size
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
    mail.body = "x-list-name: #{list.email}\nX-ADD-KEY:\nx-stop:\nlakdsjflaksjdflakjsdflkajsdf\n"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num)
    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s).to eql('In the message you sent us, no keys could be found. :(')

    teardown_list_and_mailer(list)
  end

  it 'x-fetch-key with invalid input' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list_keys_num = list.keys.size
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
    mail.body = "x-list-name: #{list.email}\nX-fetch-KEY: lala!\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num)
    expect(message.to_s).to include('Invalid input.')

    teardown_list_and_mailer(list)
  end

  it 'x-fetch-key with email address' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list_keys_num = list.keys.size
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
    mail.body = "x-list-name: #{list.email}\nX-fetch-KEY: admin@example.org\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    with_sks_mock(list.listdir) do
      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
    end
    raw = Mail::TestMailer.deliveries.find { |message| message.to == [list.admins.first.email] }
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num + 1)
    expect(message.first_plaintext_part.body.to_s).to match(/This key was fetched \(new key\):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo \d{4}-\d{2}-\d{2} \[expired: \d{4}-\d{2}-\d{2}\]\n/)

    teardown_list_and_mailer(list)
  end

  it 'x-fetch-key with unknown email-address' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list_keys_num = list.keys.size
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
    mail.body = "x-list-name: #{list.email}\nX-fetch-KEY: something@localhost\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    with_sks_mock(list.listdir) do
      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
    end
    raw = Mail::TestMailer.deliveries.find { |message| message.to == [list.admins.first.email] }
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num)
    expect(message.to_s).to include('Fetching something@localhost did not succeed')

    teardown_list_and_mailer(list)
  end

  it 'x-fetch-key with URL' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list_keys_num = list.keys.size
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
    mail.body = "x-list-name: #{list.email}\nX-fetch-KEY: http://127.0.0.1:9999/keys/example.asc\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    with_sks_mock(list.listdir) do
      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
    end
    raw = Mail::TestMailer.deliveries.find { |message| message.to == [list.admins.first.email] }
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num + 1)
    expect(message.first_plaintext_part.body.to_s).to match(/This key was fetched \(new key\):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo \d{4}-\d{2}-\d{2} \[expired: \d{4}-\d{2}-\d{2}\]\n/)

    teardown_list_and_mailer(list)
  end

  it 'x-fetch-key with invalid URL' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list_keys_num = list.keys.size
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
    url = 'http://localhost:9999/foo'
    mail.body = "x-list-name: #{list.email}\nX-fetch-KEY: #{url}\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    with_sks_mock(list.listdir) do
      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
    end
    raw = Mail::TestMailer.deliveries.find { |message| message.to == [list.admins.first.email] }
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num)
    expect(message.to_s).to include("Fetching #{url} did not succeed")

    teardown_list_and_mailer(list)
  end

  it 'x-fetch-key with unknown fingerprint' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list_keys_num = list.keys.size
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
    mail.body = "x-list-name: #{list.email}\nX-fetch-KEY: 0x0000000000000000000000000000000000000000\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    with_sks_mock(list.listdir) do
      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
    end
    raw = Mail::TestMailer.deliveries.find { |message| message.to == [list.admins.first.email] }
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num)
    expect(message.to_s).to include('Fetching 0x0000000000000000000000000000000000000000 did not succeed')

    teardown_list_and_mailer(list)
  end

  it 'x-fetch-key with fingerprint' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list_keys_num = list.keys.size
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
    mail.body = "x-list-name: #{list.email}\nX-fetch-KEY: 0x98769E8A1091F36BD88403ECF71A3F8412D83889\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    with_sks_mock(list.listdir) do
      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
    end
    raw = Mail::TestMailer.deliveries.find { |message| message.to == [list.admins.first.email] }
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num + 1)
    expect(message.first_plaintext_part.body.to_s).to match(/This key was fetched \(new key\):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo \d{4}-\d{2}-\d{2} \[expired: \d{4}-\d{2}-\d{2}\]\n/)

    teardown_list_and_mailer(list)
  end

  it 'x-fetch-key with fingerprint of unchanged key' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list_keys_num = list.keys.size
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
    mail.body = "x-list-name: #{list.email}\nX-fetch-KEY: 0x59C71FB38AEE22E091C78259D06350440F759BD3\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    with_sks_mock(list.listdir) do
      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
    end
    raw = Mail::TestMailer.deliveries.find { |message| message.to == [list.admins.first.email] }
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num)
    expect(message.first_plaintext_part.body.to_s).to match(/This key was fetched \(unchanged\):\n0x59C71FB38AEE22E091C78259D06350440F759BD3 schleuder@example.org \d{4}-\d{2}-\d{2}/)

    teardown_list_and_mailer(list)
  end

  it 'x-fetch-key without arguments' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list_keys_num = list.keys.size
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
    mail.body = "x-list-name: #{list.email}\nX-fetch-KEY: \nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    with_sks_mock(list.listdir) do
      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
    end
    raw = Mail::TestMailer.deliveries.find { |message| message.to == [list.admins.first.email] }
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num)
    expect(message.to_s).not_to include('translation missing')
    expect(message.first_plaintext_part.body.to_s).to eql(I18n.t('keyword_handlers.key_management.fetch_key_requires_arguments'))

    teardown_list_and_mailer(list)
  end

  it 'x-resend' do
    list = create(:list, public_footer: "-- \nblablabla")
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: #{list.email}\nX-resend: someone@example.org\nx-stop\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    resent_message = raw.verify
    resent_message_body = resent_message.parts.map { |p| p.body.to_s }.join
    raw = Mail::TestMailer.deliveries.last
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('Resent: Unencrypted to someone@example.org')
    expect(resent_message.to).to include('someone@example.org')
    expect(resent_message.to_s).not_to include('Resent: Unencrypted to someone@example.org')
    expect(resent_message_body).to eql(content_body + list.public_footer.to_s)

    teardown_list_and_mailer(list)
  end

  it 'does not parse keywords once the mail body started' do
    list = create(:list, public_footer: "-- \nblablabla")
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = <<EOS
Hello again!

Did you know that you can resend emails using the following keyword:

x-resend: foo@example.com

Don't forget to prefix it with

x-list-name: yourlist@example.com

Otherwise it won't be sent out. What a nice trick!

Best
EOS
    mail.body = "x-list-name: #{list.email}\nX-resend: someone@example.org\nx-stop\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    expect(Mail::TestMailer.deliveries.length).to eql(2)
    raw = Mail::TestMailer.deliveries.first
    resent_message = raw.verify
    resent_message_body = resent_message.parts.map { |p| p.body.to_s }.join
    raw = Mail::TestMailer.deliveries.last
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('Resent: Unencrypted to someone@example.org')
    expect(resent_message.to).to include('someone@example.org')
    expect(resent_message.to_s).not_to include('Resent: Unencrypted to someone@example.org')
    expect(resent_message_body).to eql(content_body + list.public_footer.to_s)

    teardown_list_and_mailer(list)
  end

  it 'x-resend does not include internal_footer' do
    list = create(
      :list,
      internal_footer: "-- \nsomething private",
      public_footer: "-- \nsomething public"
    )
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: #{list.email}\nX-resend: someone@example.org\nx-stop\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    resent_message = raw.verify
    resent_message_body = resent_message.parts.map { |p| p.body.to_s }.join

    expect(resent_message_body).not_to include(list.internal_footer)
    expect(resent_message_body).to eql(content_body + list.public_footer.to_s)

    teardown_list_and_mailer(list)
  end

  it 'x-resend with iso-8859-1 body' do
    list = create(:list, public_footer: "-- \nblablabla")
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again! ¡Hola!\r\n"
    mail.charset = 'iso-8859-1'
    mail.body = "x-list-name: #{list.email}\nX-resend: someone@example.org\nx-stop\n#{content_body}".encode('iso-8859-1')
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    resent_message = raw.verify
    raw = Mail::TestMailer.deliveries.last
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('Resent: Unencrypted to someone@example.org')
    expect(message.parts[1].decoded.force_encoding(message.parts[1].charset)).to eql(content_body.encode(message.parts[1].charset))
    expect(resent_message.to).to include('someone@example.org')
    expect(resent_message.to_s).not_to include('Resent: Unencrypted to someone@example.org')
    expect(resent_message.parts[0].decoded).to eql(content_body.encode(resent_message.parts[0].charset))
    expect(resent_message.parts[1].decoded).to eql(list.public_footer.to_s)

    teardown_list_and_mailer(list)
  end

  it 'x-resend with utf-8 body and umlauts' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "This is a test\r\nAnd here are some umlauts:ÄäÖöÜüß"
    mail.charset = 'utf-8'
    mail.body = "x-list-name: #{list.email}\nX-resend: someone@example.org\nx-stop\n#{content_body}".encode('utf-8')
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    resent_message = raw.verify
    raw = Mail::TestMailer.deliveries.last
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('Resent: Unencrypted to someone@example.org')
    expect(message.parts[1].decoded.force_encoding(message.parts[1].charset)).to eql(content_body.encode(message.parts[1].charset))
    expect(resent_message.to).to include('someone@example.org')
    expect(resent_message.to_s).not_to include('Resent: Unencrypted to someone@example.org')
    expect(resent_message.parts[0].decoded).to eql(content_body.encode(resent_message.parts[0].charset))

    teardown_list_and_mailer(list)
  end

  it 'x-resend with admin-notification' do
    list = create(:list, keywords_admin_notify: ['resend'])
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: #{list.email}\nX-resend: someone@example.org\nx-stop\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries[1]
    notification = Mail.create_message_to_list(raw.to_s, list.email, list).setup
    raw = Mail::TestMailer.deliveries[2]
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(Mail::TestMailer.deliveries.size).to eql(3)

    expect(notification.to).to eql(['schleuder@example.org'])
    expect(notification.first_plaintext_part.body.to_s).to eql("schleuder@example.org sent this keyword to the list:\n\nresend: someone@example.org\n")

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('Resent: Unencrypted to someone@example.org')

    teardown_list_and_mailer(list)
  end

  it 'x-resend with admin-notification and admin has delivery disabled' do
    list = create(:list, keywords_admin_notify: ['resend'])
    list.subscribe('user@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3')
    list.subscribe('admin@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true, false)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: #{list.email}\nX-resend: someone@example.org\nx-stop\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries[1]
    notification = Mail.create_message_to_list(raw.to_s, list.email, list).setup
    raw = Mail::TestMailer.deliveries[2]
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(Mail::TestMailer.deliveries.size).to eql(3)

    expect(notification.to).to eql(['admin@example.org'])
    expect(notification.first_plaintext_part.body.to_s).to eql("admin@example.org sent this keyword to the list:\n\nresend: someone@example.org\n")

    expect(message.to).to eql(['user@example.org'])
    expect(message.to_s).to include('Resent: Unencrypted to someone@example.org')

    teardown_list_and_mailer(list)
  end

  it 'x-resend without x-list-name' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "X-resend: someone@example.org\nx-stop\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).not_to include('Resent: Unencrypted to someone@example.org')
    expect(message.to_s).to include(%[Your message did not contain the required "X-LIST-NAME" keyword and was rejected.])

    teardown_list_and_mailer(list)
  end

  it 'x-resend-encrypted-only with matching key' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: #{list.email}\nX-resend-encrypted-only: bla@foo\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    resent_message = Mail::TestMailer.deliveries.first
    raw = Mail::TestMailer.deliveries.last
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(list.keys('bla@foo').size).to eql(1)
    expect(resent_message.to).to eql(['bla@foo'])
    expect(resent_message.content_type).to match(/^multipart\/encrypted.*application\/pgp-encrypted/)
    expect(message.first_plaintext_part.body.to_s).to include("Resent: Encrypted to
  bla@foo (87E65ED2081AE3D16BE4F0A5EBDBE899251F2412)")

    teardown_list_and_mailer(list)
  end

  it 'x-resend-cc-encrypted-only with matching key' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: #{list.email}\nX-resend-cc-encrypted-only: bla@foo\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    resent_message = Mail::TestMailer.deliveries.first
    raw = Mail::TestMailer.deliveries.last
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(list.keys('bla@foo').size).to eql(1)
    expect(resent_message.cc).to eql(['bla@foo'])
    expect(resent_message.content_type).to match(/^multipart\/encrypted.*application\/pgp-encrypted/)
    expect(message.first_plaintext_part.body.to_s).to include("ResentCc: Encrypted to
  bla@foo (87E65ED2081AE3D16BE4F0A5EBDBE899251F2412)")

    teardown_list_and_mailer(list)
  end

  it 'x-resend-cc-encrypted-only to 2 addresses with matching keys' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: #{list.email}\nX-resend-cc-encrypted-only: schleuder@example.org bla@foo\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    resent_message = Mail::TestMailer.deliveries.first
    raw = Mail::TestMailer.deliveries.last
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(list.keys('bla@foo').size).to eql(1)
    expect(resent_message.cc).to eql(['schleuder@example.org','bla@foo'])
    expect(resent_message.content_type).to match(/^multipart\/encrypted.*application\/pgp-encrypted/)
    expect(message.first_plaintext_part.body.to_s).to include("ResentCc: Encrypted to
  schleuder@example.org (59C71FB38AEE22E091C78259D06350440F759BD3),
  bla@foo (87E65ED2081AE3D16BE4F0A5EBDBE899251F2412)")

    teardown_list_and_mailer(list)
  end

  it 'x-resend-cc-encrypted-only to 2 addresses with one missing keys' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    expect(list.keys('bla@foo').size).to eql(0)
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: #{list.email}\nX-resend-cc-encrypted-only: schleuder@example.org bla@foo\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    expect(Mail::TestMailer.deliveries.size).to eql(1)
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(message.first_plaintext_part.body.to_s).to include("Sig: Good signature from D06350440F759BD3 Schleuder TestUser
  <schleuder@example.org>
Enc: Encrypted
Error: Resending to <bla@foo> failed (0 keys found, of which 0 can be used.
  Unencrypted sending not allowed).
Error: Resending to <schleuder@example.org> aborted due to other errors.")

    teardown_list_and_mailer(list)
  end

  it 'x-resend-cc-encrypted-only to 3 addresses with one missing keys' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))
    expect(list.keys('bla@foo').size).to eql(1)
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: #{list.email}\nX-resend-cc-encrypted-only: schleuder@example.org foo@bla bla@foo\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    expect(Mail::TestMailer.deliveries.size).to eql(1)
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(message.first_plaintext_part.body.to_s).to include("Error: Resending to <foo@bla> failed (0 keys found, of which 0 can be used.
  Unencrypted sending not allowed).
Error: Resending to <schleuder@example.org> aborted due to other errors.
Error: Resending to <bla@foo> aborted due to other errors.")

    teardown_list_and_mailer(list)
  end

  it 'x-resend-cc to 2 addresses with missing keys' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: #{list.email}\nX-resend-cc: foo@bla bla@foo\n#{content_body}"
    expect(list.keys('foo@bla').size).to eql(0)
    expect(list.keys('bla@foo').size).to eql(0)
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    resent_message = Mail::TestMailer.deliveries.first
    raw = Mail::TestMailer.deliveries.last
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(resent_message.cc).to eql(['foo@bla','bla@foo'])
    expect(resent_message.content_type).to match(/^multipart\/signed.*application\/pgp-signature/)
    expect(message.first_plaintext_part.body.to_s).to include('ResentCc: Unencrypted to foo@bla, bla@foo')

    teardown_list_and_mailer(list)
  end

  it 'x-resend-cc to 2 addresses with one missing keys' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: #{list.email}\nX-resend-cc: foo@bla bla@foo\n#{content_body}"
    expect(list.keys('foo@bla').size).to eql(0)
    expect(list.keys('bla@foo').size).to eql(1)
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    resent_message = Mail::TestMailer.deliveries.first
    raw = Mail::TestMailer.deliveries.last
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(resent_message.cc).to eql(['foo@bla','bla@foo'])
    expect(resent_message.content_type).to match(/^multipart\/signed.*application\/pgp-signature/)
    expect(message.first_plaintext_part.body.to_s).to include('ResentCc: Unencrypted to foo@bla, bla@foo')

    teardown_list_and_mailer(list)
  end

  it 'x-resend-cc-encrypted-only to 2 addresses with missing keys' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: #{list.email}\nX-resend-cc-encrypted-only: foo@bla bla@foo\n#{content_body}"
    expect(list.keys('foo@bla').size).to eql(0)
    expect(list.keys('bla@foo').size).to eql(0)
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    expect(Mail::TestMailer.deliveries.size).to eql(1)
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(list.keys('bla@foo').size).to eql(0)
    expect(message.first_plaintext_part.body.to_s).to include("Error: Resending to <foo@bla> failed (0 keys found, of which 0 can be used.
  Unencrypted sending not allowed).
Error: Resending to <bla@foo> failed (0 keys found, of which 0 can be used.
  Unencrypted sending not allowed).")

    teardown_list_and_mailer(list)
  end

  it 'x-resend-encrypted-only with two matching keys, one of which is expired' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    list.import_key(File.read('spec/fixtures/expired_key.txt'))
    list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: #{list.email}\nX-resend-encrypted-only: bla@foo\nx-stop\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    resent_message = Mail::TestMailer.deliveries.first
    raw = Mail::TestMailer.deliveries.last
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(list.keys('bla@foo').size).to eql(2)
    expect(resent_message.to).to eql(['bla@foo'])
    expect(resent_message.content_type).to match(/^multipart\/encrypted.*application\/pgp-encrypted/)
    expect(message.first_plaintext_part.body.to_s).to include("Resent: Encrypted to
  bla@foo (87E65ED2081AE3D16BE4F0A5EBDBE899251F2412)")

    teardown_list_and_mailer(list)
  end

  it 'x-resend-unencrypted with matching key' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: #{list.email}\nX-resend-unencrypted: bla@foo\nx-stop\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    resent_message = Mail::TestMailer.deliveries.first
    raw = Mail::TestMailer.deliveries.last
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(list.keys('bla@foo').size).to eql(1)
    expect(resent_message.to).to eql(['bla@foo'])
    expect(resent_message.content_type).to_not match(/^multipart\/encrypted.*application\/pgp-encrypted/)
    expect(resent_message.first_plaintext_part.body.to_s).to include('Hello again!')
    expect(message.first_plaintext_part.body.to_s).to include('Resent: Unencrypted to bla@foo')

    teardown_list_and_mailer(list)
  end

  it 'x-resend-encrypted-only with expired key' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    list.import_key(File.read('spec/fixtures/expired_key.txt'))
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: #{list.email}\nX-resend-encrypted-only: bla@foo\nx-stop\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(list.keys('bla@foo').size).to eql(1)
    expect(message.first_plaintext_part.to_s).to include("Error: Resending to <bla@foo> failed (1 keys found, of which 0 can be used.\r\n  Unencrypted sending not allowed).")

    teardown_list_and_mailer(list)
  end

  it 'x-resend-cc-encrypted-only with expired key' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    list.import_key(File.read('spec/fixtures/expired_key.txt'))
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: #{list.email}\nX-resend-cc-encrypted-only: bla@foo\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(list.keys('bla@foo').size).to eql(1)
    expect(message.first_plaintext_part.to_s).to include("Error: Resending to <bla@foo> failed (1 keys found, of which 0 can be used.\r\n  Unencrypted sending not allowed).")

    teardown_list_and_mailer(list)
  end

  it 'x-resend with wrong x-list-name' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-list-name: somethingelse@example.org\nX-resend: someone@example.org\nx-stop\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).not_to include('Resent: Unencrypted to someone@example.org')
    expect(message.to_s).to include(%[Your message contained an incorrect "X-LIST-NAME" keyword. The keyword argument must match the email address of this list.])

    teardown_list_and_mailer(list)
  end

  it 'x-resend with invalid recipient' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    invalid_recipient = '`ls`bla'
    mail.body = "x-list-name: #{list.email}\nX-resend: #{invalid_recipient}\nx-stop\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    delivered_emails = Mail::TestMailer.deliveries
    raw = delivered_emails.first
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(delivered_emails.size).to eql(1)
    expect(message.to_s).not_to include('Resent: Unencrypted to someone@example.org')
    expect(message.to_s).to include("Error: Invalid email-address for resending: #{invalid_recipient}")

    teardown_list_and_mailer(list)
  end

  it 'x-sign-this with inline text' do
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
    signed_text = "signed\nsigned\nsigned\n\n"
    mail.body = "x-list-name: #{list.email}\nx-sign-this:\nx-stop\n#{signed_text}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(message.to_s.gsub("\r", '')).to match(/BEGIN PGP SIGNED MESSAGE-----\nHash: SHA(256|512)\n\n#{signed_text}-----BEGIN PGP SIGNATURE/)

    teardown_list_and_mailer(list)
  end

  it 'x-sign-this with attachments' do
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
    keywords = Mail::Part.new
    keywords.body = "\n\nx-list-name: #{list.email}\nx-sign-this:\nx-stop"
    mail.parts << keywords
    signed_content = File.read('spec/fixtures/example_key.txt')
    mail.attachments['example_key.txt'] = { mime_type: 'application/pgp-key',
                                            content: signed_content }
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup
    signature = message.attachments.first.body.to_s
    # list.gpg.verify() results in a "Bad Signature".  The sign-this keyword-handler
    # also uses GPGME::Crypto, apparently that makes a difference.
    crypto = GPGME::Crypto.new
    verification_string = ''
    crypto.verify(signature, {signed_text: signed_content}) do |sig|
      verification_string = sig.to_s
    end

    expect(message.to_s).to include('Find the signatures attached.')
    expect(message.attachments.size).to eql(1)
    expect(message.attachments.first.filename).to eql('example_key.txt.sig')
    expect(verification_string).to include('Good signature from D06350440F759BD3')

    teardown_list_and_mailer(list)
  end

  it 'x-list-key with arbitrary email-sub-string' do
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
    mail.body = "x-list-name: #{list.email}\nX-list-KEYs: der@ex\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to match(/pub   4096R\/59C71FB38AEE22E091C78259D06350440F759BD3 \d{4}-\d{2}-\d{2}/)
    expect(message.to_s.scan(/^pub /).size).to eql(1)

    teardown_list_and_mailer(list)
  end

  it 'x-list-key with correctly prefixed email-sub-string' do
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
    mail.body = "x-list-name: #{list.email}\nX-list-KEYs: @schleuder\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to match(/pub   4096R\/59C71FB38AEE22E091C78259D06350440F759BD3 \d{4}-\d{2}-\d{2}/)
    expect(message.to_s.scan(/^pub /).size).to eql(1)

    teardown_list_and_mailer(list)
  end

  it 'x-list-key with prefixed fingerprint' do
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
    mail.body = "x-list-name: #{list.email}\nX-list-KEYs: 0x59C71FB38AEE22E091C78259D06350440F759BD3\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to match(/pub   4096R\/59C71FB38AEE22E091C78259D06350440F759BD3 \d{4}-\d{2}-\d{2}/)
    expect(message.to_s.scan(/^pub /).size).to eql(1)

    teardown_list_and_mailer(list)
  end


  it 'x-get-key with valid argument' do
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
    mail.body = "x-list-name: #{list.email}\nX-GET-KEY: 0x59C71FB38AEE22E091C78259D06350440F759BD3\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to match(/pub   4096R\/59C71FB38AEE22E091C78259D06350440F759BD3 \d{4}-\d{2}-\d{2}/)
    expect(message.to_s).to include('-----BEGIN PGP PUBLIC KEY')

    teardown_list_and_mailer(list)
  end

  it 'x-get-key with invalid argument' do
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
    mail.body = "x-list-name: #{list.email}\nX-get-KEY: blabla\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('No match found for')
    expect(message.to_s).not_to include('-----BEGIN PGP PUBLIC KEY')

    teardown_list_and_mailer(list)
  end

  it 'x-get-key with empty argument' do
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
    mail.body = "x-list-name: #{list.email}\nX-get-KEY:\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('Your message resulted in no output')
    expect(message.to_s).not_to include('-----BEGIN PGP PUBLIC KEY')

    teardown_list_and_mailer(list)
  end

  it 'x-delete-key with valid argument' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    list_keys_num = list.keys.size
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
    mail.body = "x-list-name: #{list.email}\nX-delete-KEY: C4D60F8833789C7CAA44496FD3FFA6613AB10ECE\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num - 1)
    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s).to match(/^This key was deleted:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org \d{4}-\d{2}-\d{2}\n$/)

    teardown_list_and_mailer(list)
  end

  it 'x-delete-key with invalid argument' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    list_keys_num = list.keys.size
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
    mail.body = "x-list-name: #{list.email}\nX-delete-KEY: lala\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num)
    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('No match found for')
    expect(message.to_s).not_to include('This key was deleted:')

    teardown_list_and_mailer(list)
  end

  it 'x-delete-key with not distinctly matching argument' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    list_keys_num = list.keys.size
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
    mail.body = "x-list-name: #{list.email}\nX-delete-KEY: schleuder\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num)
    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include('Too many matching keys for ')
    expect(message.to_s).not_to include('Deleted')

    teardown_list_and_mailer(list)
  end

  it 'x-delete-key without argument' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    list_keys_num = list.keys.size
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
    mail.body = "x-list-name: #{list.email}\nX-delete-KEY:\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(list.keys.size).to eql(list_keys_num)
    expect(message.to_s).not_to include('translation missing')
    expect(message.first_plaintext_part.body.to_s).to eql(I18n.t('keyword_handlers.key_management.delete_key_requires_arguments'))

    teardown_list_and_mailer(list)
  end

  it 'x-get-logfile with debug level sends non-empty logfile' do
    list = create(:list)
    list.update_attribute(:log_level, 'debug')
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
    mail.body = "x-list-name: #{list.email}\nX-get-logfile\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.parts.last.body.to_s.lines.size).to be > 1
    expect(message.parts.last.body.to_s).to include('Logfile created on')
    expect(message.parts.last.body.to_s).to include('DEBUG')

    teardown_list_and_mailer(list)
  end

  it 'x-get-logfile with error-level sends empty logfile' do
    list = create(:list)
    list.update_attribute(:log_level, 'error')
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
    mail.body = "x-list-name: #{list.email}\nX-get-logfile\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s.lines.size).to eql(1)
    expect(message.body.to_s).to include('Logfile created on')

    teardown_list_and_mailer(list)
  end

  it 'x-attach-listkey' do
    list = create(:list, log_level: 'debug')
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = 'something something list-key'
    mail.body = "x-list-name: #{list.email}\nX-attach-listkey\nx-stop\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(message.parts.length).to eql(2)
    expect(message.parts.last.parts.length).to eql(2)
    expect(message.parts.last.parts.first.body.to_s).to eql(content_body)
    expect(message.parts.last.parts.last.content_type.to_s).to eql('application/pgp-keys')
    expect(message.parts.last.parts.last.body.decoded).to match(/pub   4096R\/59C71FB38AEE22E091C78259D06350440F759BD3 \d{4}-\d{2}-\d{2}/)
    expect(message.parts.last.parts.last.body.decoded).to include('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(message.parts.last.parts.last.body.decoded).to include('mQINBFhGvz0BEADXbbTWo/PStyTznAo/f1UobY0EiVPNKNERvYua2Pnq8BwOQ5bS')

    teardown_list_and_mailer(list)
  end

  it 'x-attach-listkey from Thunderbird with protected headers' do
    list = create(:list, email: 'testlist@example.net')
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    encrypted_mail = File.read('spec/fixtures/mails/attach-list-key-thunderbird.eml')

    res = nil
    begin
      res = Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(message.parts.length).to eql(2)
    expect(message.parts.last.parts.length).to eql(2)
    expect(message.parts.last.parts.first.decoded).to eql("Hallo\r\n\r\nkurz mal testen, wie ein resend mail, wo zusätzlich der listkey attached\r\nist bei euch so ankommt.\r\n\r\nich habe das gefühl hier ist as broken.\r\n\r\n\r\n\r\n\r\n")
    expect(message.parts.last.parts.last.content_type.to_s).to eql('application/pgp-keys')
    expect(message.parts.last.parts.last.body.decoded).to match(/pub   4096R\/59C71FB38AEE22E091C78259D06350440F759BD3 \d{4}-\d{2}-\d{2}/)
    expect(message.parts.last.parts.last.body.decoded).to include('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(message.parts.last.parts.last.body.decoded).to include('mQINBFhGvz0BEADXbbTWo/PStyTznAo/f1UobY0EiVPNKNERvYua2Pnq8BwOQ5bS')

    teardown_list_and_mailer(list)
  end

  it 'x-get-version' do
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
    mail.body = "x-list-name: #{list.email}\nX-get-version\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s.lines.size).to eql(1)
    expect(message.first_plaintext_part.body.to_s).to eql(Schleuder::VERSION)

    teardown_list_and_mailer(list)
  end

  it 'x-get-version with deprecated x-listname keyword' do
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
    mail.body = "x-listname: #{list.email}\nX-get-version\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s.lines.size).to eql(1)
    expect(message.first_plaintext_part.body.to_s).to eql(Schleuder::VERSION)

    teardown_list_and_mailer(list)
  end

  it 'x-get-version with delivery disabled' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true, false)
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
    mail.body = "x-listname: #{list.email}\nX-get-version\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s.lines.size).to eql(1)
    expect(message.first_plaintext_part.body.to_s).to eql(Schleuder::VERSION)

    teardown_list_and_mailer(list)
  end

  it 'x-list-keys without arguments' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))
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
    mail.body = "x-list-name: #{list.email}\nX-list-keys\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.first_plaintext_part.body.to_s.lines.size).to eql(16)
    expect(message.first_plaintext_part.body.to_s).to include('59C71FB38AEE22E091C78259D06350440F759BD3')
    expect(message.first_plaintext_part.body.to_s).to include('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    expect(message.first_plaintext_part.body.to_s).to include('87E65ED2081AE3D16BE4F0A5EBDBE899251F2412')

    teardown_list_and_mailer(list)
  end

  it 'x-list-keys with one argument' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))
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
    mail.body = "x-list-name: #{list.email}\nX-list-keys schleuder2\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.first_plaintext_part.body.to_s.lines.size).to eql(4)
    expect(message.first_plaintext_part.body.to_s).not_to include('59C71FB38AEE22E091C78259D06350440F759BD3')
    expect(message.first_plaintext_part.body.to_s).to include('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    expect(message.first_plaintext_part.body.to_s).not_to include('87E65ED2081AE3D16BE4F0A5EBDBE899251F2412')

    teardown_list_and_mailer(list)
  end

  it 'x-list-keys with two arguments' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))
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
    mail.body = "x-list-name: #{list.email}\nX-list-keys schleuder2 bla\nx-stop"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.first_plaintext_part.body.to_s.lines.size).to eql(10)
    expect(message.first_plaintext_part.body.to_s).not_to include('59C71FB38AEE22E091C78259D06350440F759BD3')
    expect(message.first_plaintext_part.body.to_s).to include('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    expect(message.first_plaintext_part.body.to_s).to include('87E65ED2081AE3D16BE4F0A5EBDBE899251F2412')

    teardown_list_and_mailer(list)
  end

  context 'with broken utf8 in key' do
    it 'x-list-keys works' do
      list = create(:list)
      list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
      list.import_key(File.read('spec/fixtures/example_key.txt'))
      list.import_key(File.read('spec/fixtures/broken_utf8_uid_key.txt'))
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
      mail.body = "x-list-name: #{list.email}\nX-list-keys\nx-stop"
      mail.deliver

      encrypted_mail = Mail::TestMailer.deliveries.first
      Mail::TestMailer.deliveries.clear

      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
      raw = Mail::TestMailer.deliveries.first
      message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

      expect(message.first_plaintext_part.body.to_s.lines.size).to eql(16)
      expect(message.first_plaintext_part.body.to_s).to include('59C71FB38AEE22E091C78259D06350440F759BD3')
      expect(message.first_plaintext_part.body.to_s).to include('3102B29989BEE703AE5ED62E1242F6E13D8EBE4A')

      teardown_list_and_mailer(list)
    end
    it 'x-add-key with inline key-material' do
      list = create(:list, keywords_admin_notify: [])
      list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
      list_keys_num = list.keys.size
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
      keymaterial = File.read('spec/fixtures/broken_utf8_uid_key.txt')
      mail.body = "x-list-name: #{list.email}\nX-ADD-KEY:\nx-stop\n#{keymaterial}"
      mail.deliver

      encrypted_mail = Mail::TestMailer.deliveries.first
      Mail::TestMailer.deliveries.clear

      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
      raw = Mail::TestMailer.deliveries.first
      message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

      expect(list.keys.size).to eql(list_keys_num + 1)
      expect(message.to).to eql(['schleuder@example.org'])
      expect(message.first_plaintext_part.body.to_s).to match(/This key was newly added:\n0x3102B29989BEE703AE5ED62E1242F6E13D8EBE4A info@buendnis-gegen-rechts.ch \d{4}-\d{2}-\d{2}\n/)

      teardown_list_and_mailer(list)
    end
    it 'x-get-key with valid argument' do
      list = create(:list)
      list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
      list.import_key(File.read('spec/fixtures/broken_utf8_uid_key.txt'))
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
      mail.body = "x-list-name: #{list.email}\nX-GET-KEY: 0x3102B29989BEE703AE5ED62E1242F6E13D8EBE4A\nx-stop"
      mail.deliver

      encrypted_mail = Mail::TestMailer.deliveries.first
      Mail::TestMailer.deliveries.clear

      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
      raw = Mail::TestMailer.deliveries.first
      message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

      expect(message.to_s).to match(/pub   1024D\/3102B29989BEE703AE5ED62E1242F6E13D8EBE4A \d{4}-\d{2}-\d{2}/)
      expect(message.to_s).to include('-----BEGIN PGP PUBLIC KEY')

      teardown_list_and_mailer(list)
    end
  end

  it 'rejects messages to request-address without x-stop keyword' do
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
    mail.body = "x-list-name: #{list.email}\nX-LIST-KEYS"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(Mail::TestMailer.deliveries.size).to eql(1)
    expect(message.first_plaintext_part.body.to_s).to include("Your message lacked the keyword 'X-STOP'")

    teardown_list_and_mailer(list)
  end

  it 'rejects messages to list-address without x-stop keyword' do
    list = create(:list)
    list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    mail.body = "x-list-name: #{list.email}\nX-resend: someone@localhost"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(Mail::TestMailer.deliveries.size).to eql(1)
    expect(message.first_plaintext_part.body.to_s).to include("Your message lacked the keyword 'X-STOP'")

    teardown_list_and_mailer(list)
  end
end
