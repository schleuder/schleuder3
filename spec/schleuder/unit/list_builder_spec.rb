require 'spec_helper'

describe Schleuder::ListBuilder do

  it 'creates a new, valid list' do
    listname = "list-#{rand}@example.org"
    adminaddress = 'schleuder2@example.org'
    adminkey = File.read('spec/fixtures/example_key.txt')
    list, messages = ListBuilder.new({email: listname, fingerprint: nil}, adminaddress, nil, adminkey).run
    expect(list).to be_an_instance_of Schleuder::List
    expect(list).to be_valid
    expect(messages).to be_blank
  end

  it 'returns an error-message if given an invalid email-address' do
    listname = "list-#{rand}"
    adminaddress = 'schleuder2@example.org'
    adminkey = File.read('spec/fixtures/example_key.txt')
    list, messages = ListBuilder.new({email: listname, fingerprint: nil}, adminaddress, nil, adminkey).run
    expect(list).to be_nil
    expect(messages).to be_an_instance_of Hash
    expect(messages.keys).to eq ['email']
    expect(messages.values).to be_present
  end

  it 'returns an error-message if given an invalid email-address with a space' do
    listname = "list #{rand}@example.com"
    adminaddress = 'schleuder2@example.org'
    adminkey = File.read('spec/fixtures/example_key.txt')
    list, messages = ListBuilder.new({email: listname, fingerprint: nil}, adminaddress, nil, adminkey).run
    expect(list).to be_nil
    expect(messages).to be_an_instance_of Hash
    expect(messages.keys).to eq ['email']
    expect(messages.values).to be_present
  end

  it 'creates a listdir for the list' do
    listname = "list-#{rand}@example.org"
    adminaddress = 'schleuder2@example.org'
    adminkey = File.read('spec/fixtures/example_key.txt')
    list, _ = ListBuilder.new({email: listname, fingerprint: nil}, adminaddress, nil, adminkey).run
    expect(File.directory?(list.listdir)).to be true
  end

  it 'creates a list-key with all required UIDs' do
    listname = "list-#{rand}@example.org"
    adminaddress = 'schleuder2@example.org'
    adminkey = File.read('spec/fixtures/example_key.txt')
    list, _ = ListBuilder.new({email: listname, fingerprint: nil}, adminaddress, nil, adminkey).run
    uids = list.key.uids.map(&:email)
    expect(uids.first).to eql(list.email)
    expect(uids).to include(list.request_address)
    expect(uids).to include(list.owner_address)
  end

  it 'subscribes the adminaddress and imports the adminkey' do
    listname = "list-#{rand}@example.org"
    adminaddress = 'schleuder2@example.org'
    adminkey = File.read('spec/fixtures/example_key.txt')
    list, _ = ListBuilder.new({email: listname, fingerprint: nil}, adminaddress, nil, adminkey).run

    subscription_emails = list.subscriptions.map(&:email)
    keys_fingerprints = list.keys.map(&:fingerprint)

    expect(subscription_emails).to eq [adminaddress]
    expect(keys_fingerprints).to include('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
  end

  it 'subscribes the adminaddress and respects the given adminfingerprint' do
    listname = "list-#{rand}@example.org"
    adminaddress = 'schleuder2@example.org'
    list, _ = ListBuilder.new({email: listname, fingerprint: nil}, adminaddress, '59C71FB38AEE22E091C78259D06350440F759BD3').run

    subscription_emails = list.subscriptions.map(&:email)
    admin_subscription = list.admins.first

    expect(subscription_emails).to eq [adminaddress]
    expect(admin_subscription.fingerprint).to eql('59C71FB38AEE22E091C78259D06350440F759BD3')
  end

  it 'subscribes the adminaddress and ignores the adminfingerprint if an adminkey was given' do
    listname = "list-#{rand}@example.org"
    adminaddress = 'schleuder2@example.org'
    adminkey = File.read('spec/fixtures/example_key.txt')
    list, _ = ListBuilder.new({email: listname, fingerprint: nil}, adminaddress, '59C71FB38AEE22E091C78259D06350440F759BD3', adminkey).run

    subscription_emails = list.subscriptions.map(&:email)
    subscription_fingerprints = list.subscriptions.map(&:fingerprint)

    expect(subscription_emails).to eq [adminaddress]
    expect(subscription_fingerprints).to eq ['C4D60F8833789C7CAA44496FD3FFA6613AB10ECE']
  end

end
