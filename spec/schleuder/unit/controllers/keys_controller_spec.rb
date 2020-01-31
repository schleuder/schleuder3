require 'spec_helper'

describe Schleuder::KeysController do
  describe '#find_all' do
    it 'returns the keys for a given list id' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)

      keys = KeysController.new(account).find_all(list.email)

      expect(keys.length).to eq 1
      expect(keys).to eq [list.key]
    end

    it 'returns the keys that match a given identifier' do
      list = create(:list)
      list.import_key(File.read('spec/fixtures/example_key.txt'))
      list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)

      keys = KeysController.new(account).find_all(list.email, 'example.org')

      expect(keys.length).to eq 2
      expect(keys.map(&:fingerprint).sort).to eq %w[59C71FB38AEE22E091C78259D06350440F759BD3 C4D60F8833789C7CAA44496FD3FFA6613AB10ECE]
    end

    it 'raises an unauthorized error when the user is not authorized' do
      list = create(:list)
      unauthorized_account = create(:account, email: 'unauthorized@example.org')

      expect do
        KeysController.new(unauthorized_account).find_all(list.email)
      end.to raise_error(Schleuder::Errors::Unauthorized)
    end
  end

  describe '#import' do
    it 'imports a key for an authorized user' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      key = File.read('spec/fixtures/example_key.txt')

      expect do
        KeysController.new(account).import(list.email, key)
      end.to change { list.keys.count }.by(1)

      list.delete_key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    end

    it 'raises an unauthorized error when the user is not authorized' do
      list = create(:list)
      unauthorized_account = create(:account, email: 'unauthorized@example.org')
      key = File.read('spec/fixtures/example_key.txt')

      expect do
        KeysController.new(unauthorized_account).import(list.email, key)
      end.to raise_error(Schleuder::Errors::Unauthorized)
    end
  end

  describe '#fetch' do
    it 'asks the list to fetch a key' do
      list = create(:list)
      admin = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: admin.email)

      expect_any_instance_of(List).to receive(:fetch_keys).with('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')

      KeysController.new(account).fetch(list.email, 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    end

    it 'raises an unauthorized error when the user is not authorized' do
      list = create(:list)
      unauthorized_account = create(:account, email: 'unauthorized@example.org')

      expect do
        KeysController.new(unauthorized_account).fetch(list.email, 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
      end.to raise_error(Schleuder::Errors::Unauthorized)
    end
  end

  describe '#check' do
    it 'checks the keys of a list for an authorized user' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      list.import_key(File.read('spec/fixtures/expired_key.txt'))

      expect(KeysController.new(account).check(list.email)).to include(
        "This key is expired:\n0x98769E8A1091F36BD88403ECF71A3F8412D83889"
      )

      list.delete_key('0x70B2CF29E01AD53E')
    end

    it 'raises an unauthorized error when the user is not authorized' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      unauthorized_account = create(:account, email: subscription.email)

      expect do
        KeysController.new(unauthorized_account).check(list.email)
      end.to raise_error(Schleuder::Errors::Unauthorized)
    end
  end

  describe '#find' do
    it 'returns the key for a given fingerprint if the user is authorized' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)

      result = KeysController.new(account).find(list.email, '59C71FB38AEE22E091C78259D06350440F759BD3')

      expect(result).to be_a(GPGME::Key)
      expect(result.fingerprint).to eq '59C71FB38AEE22E091C78259D06350440F759BD3'
    end

    it 'raises an error if user is authorized but no key is found for given fingerprint' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)

      expect do
        KeysController.new(account).find(list.email, '80C71FB38AEE22E091C78259D06350440F759BD3')
      end.to raise_error(Schleuder::Errors::KeyNotFound)
    end

    it 'raises an error if user is authorized but given argument is an incomplete fingerprint' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)

      expect do
        KeysController.new(account).find(list.email, '80C71FB38AEE22E091C78259D06350440F7')
      end.to raise_error(Schleuder::Errors::KeyNotFound)
    end

    it 'raises an error if user is authorized but given argument is not a fingerprint' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)

      expect do
        KeysController.new(account).find(list.email, subscription.email)
      end.to raise_error(Schleuder::Errors::KeyNotFound)
    end

    it 'raises an unauthorized error when the user is not authorized' do
      list = create(:list)
      unauthorized_account = create(:account, email: 'unauthorized@example.org')

      expect do
        KeysController.new(unauthorized_account).find(list.email, '59C71FB38AEE22E091C78259D06350440F759BD3')
      end.to raise_error(Schleuder::Errors::Unauthorized)
    end
  end

  describe '#delete' do
    it 'deletes an existing key when user is authorized' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      key = File.read('spec/fixtures/example_key.txt')
      list.import_key(key)

      expect do
        KeysController.new(account).delete(list.email, 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
      end.to change { list.keys.count }.by(-1)
    end

    it 'raises an unauthorized error when the user is not authorized' do
      list = create(:list)
      unauthorized_account = create(:account, email: 'unauthorized@example.org')

      expect do
        KeysController.new(unauthorized_account).delete(list.email, '59C71FB38AEE22E091C78259D06350440F759BD3')
      end.to raise_error(Schleuder::Errors::Unauthorized)
    end
  end
end