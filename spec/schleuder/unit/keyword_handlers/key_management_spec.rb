require 'spec_helper'

describe Schleuder::KeywordHandlers::KeyManagement do
  it 'registers keywords' do
    found_keywords = KeywordHandlersRunner::REGISTERED_KEYWORDS.values.map do |hash|
      hash.select do |keyword, attributes|
        attributes[:klass] == Schleuder::KeywordHandlers::KeyManagement
      end.keys
    end.flatten
    
    expect(found_keywords).to eql(%w[add-key delete-key list-keys get-key fetch-key])
  end

  context '.add_key' do
    it 'imports a key from inline material' do
      mail = Mail.new
      mail.list = create(:list)
      mail.body = File.read('spec/fixtures/example_key.txt')
      mail.to_s

      list_keys = mail.list.keys
      output = KeywordHandlers::KeyManagement.new(mail: mail, arguments: []).add_key

      expect(output).to eql("This key was newly added:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org 2016-12-12\n")
      expect(mail.list.keys.size).to eql(list_keys.size + 1)
    end

    it 'imports from an inline mix of key and non-key material' do
      mail = Mail.new
      mail.list = create(:list)
      keymaterial1 = File.read('spec/fixtures/example_key.txt')
      keymaterial2 = File.read('spec/fixtures/bla_foo_key.txt')
      mail.body = "#{keymaterial1}\nsome text\n#{keymaterial2}\n--\nthis is a signature"
      mail.to_s

      list_keys = mail.list.keys
      output = KeywordHandlers::KeyManagement.new(mail: mail, arguments: []).add_key

      expect(output).to match(/^This key was newly added:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org \d{4}-\d{2}-\d{2}\n\n\nThis key was newly added:\n0x87E65ED2081AE3D16BE4F0A5EBDBE899251F2412 bla@foo \d{4}-\d{2}-\d{2}$/)
      expect(mail.list.keys.size).to eql(list_keys.size + 2)
    end

    it 'imports a key from attached material' do
      mail = Mail.new
      mail.list = create(:list)
      mail.add_file('spec/fixtures/example_key.txt')
      mail.to_s

      list_keys = mail.list.keys
      output = KeywordHandlers::KeyManagement.new(mail: mail, arguments: []).add_key

      expect(output).to eql("This key was newly added:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org 2016-12-12\n")
      expect(mail.list.keys.size).to eql(list_keys.size + 1)
    end

    it 'imports from attached quoted-printable key-material (as produced by Thunderbird)' do
      mail = Mail.new
      mail.list = create(:list)
      mail.attachments['example_key.txt'] = {
        :content_type => '"application/pgp-keys"; name="example_key.txt"',
        :content_transfer_encoding => 'quoted-printable',
        :content => File.read('spec/fixtures/example_key.txt')
      }
      mail.to_s

      list_keys = mail.list.keys
      output = KeywordHandlers::KeyManagement.new(mail: mail, arguments: []).add_key

      expect(output).to match(/^This key was newly added:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org \d{4}-\d{2}-\d{2}\n$/)
      expect(mail.list.keys.size).to eql(list_keys.size + 1)
    end

    it 'ignores body if an attachment is present' do
      mail = Mail.new
      mail.list = create(:list)
      mail.body = 'blabla'
      mail.add_file('spec/fixtures/example_key.txt')
      mail.to_s

      list_keys = mail.list.keys
      output = KeywordHandlers::KeyManagement.new(mail: mail, arguments: []).add_key

      expect(output).to eql("This key was newly added:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org 2016-12-12\n")
      expect(mail.list.keys.size).to eql(list_keys.size + 1)
    end

    it 'ignores arguments' do
      mail = Mail.new
      mail.list = create(:list)
      mail.body = 'blabla'
      mail.to_s
      list_keys = mail.list.keys
      key_material = File.read('spec/fixtures/example_key.txt').lines

      output = KeywordHandlers::KeyManagement.new(mail: mail, arguments: key_material).add_key

      expect(output).to eql('In the message you sent us, no keys could be found. :(')
      expect(mail.list.keys.size).to eql(list_keys.size)
    end

    it 'updates a key' do
      mail = Mail.new
      mail.list = create(:list)
      mail.body = 'blabla'
      mail.add_file('spec/fixtures/expired_key_extended.txt')
      mail.to_s
      mail.list.import_key(File.read('spec/fixtures/expired_key.txt'))
      list_keys = mail.list.keys

      output = KeywordHandlers::KeyManagement.new(mail: mail, arguments: []).add_key

      expect(output).to eql("This key was updated:\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo 2010-08-13 [expired: 2017-01-20]\n")
      expect(mail.list.keys.size).to eql(list_keys.size)
    end

    it 'rejects garbage' do
      mail = Mail.new
      mail.list = create(:list)
      mail.body = 'blabla'
      mail.to_s
      list_keys = mail.list.keys

      output = KeywordHandlers::KeyManagement.new(mail: mail, arguments: []).add_key

      expect(output).to eql('In the message you sent us, no keys could be found. :(')
      expect(mail.list.keys.size).to eql(list_keys.size)
    end
  end

  context '.delete_key' do
    it 'deletes a key that distinctly matches the argument' do
      mail = Mail.new
      mail.list = create(:list)
      mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
      mail.body = 'ignore me'
      mail.to_s
      list_keys = mail.list.keys

      output = KeywordHandlers::KeyManagement.new(mail: mail, arguments: ['C4D60F8833789C7CAA44496FD3FFA6613AB10ECE']).delete_key

      expect(output).to eql("This key was deleted:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org 2016-12-12\n")
      expect(mail.list.keys.size).to eql(list_keys.size - 1)
    end

    it 'deletes multiple keys that each distinctly match one argument' do
      mail = Mail.new
      mail.list = create(:list)
      mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
      mail.list.import_key(File.read('spec/fixtures/expired_key_extended.txt'))
      mail.body = 'ignore me'
      mail.to_s
      list_keys = mail.list.keys

      output = KeywordHandlers::KeyManagement.new(mail: mail, arguments: ['C4D60F8833789C7CAA44496FD3FFA6613AB10ECE', '98769E8A1091F36BD88403ECF71A3F8412D83889']).delete_key

      expect(output).to eql("This key was deleted:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org 2016-12-12\n\n\nThis key was deleted:\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo 2010-08-13 [expired: 2017-01-20]\n")
      expect(mail.list.keys.size).to eql(list_keys.size - 2)
    end

    it 'deletes no key if the argument matches but not distinctly' do
      mail = Mail.new
      mail.list = create(:list)
      mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
      mail.body = 'ignore me'
      mail.to_s
      list_keys = mail.list.keys

      output = KeywordHandlers::KeyManagement.new(mail: mail, arguments: ['schleuder']).delete_key

      expect(output).to eql("Too many matching keys for 'schleuder':\npub   4096R/59C71FB38AEE22E091C78259D06350440F759BD3 2016-12-06\nuid\t\tSchleuder TestUser <schleuder@example.org>\nsub   4096R/59C71FB38AEE22E091C78259D06350440F759BD3 2016-12-06\nsub   4096R/6B8F6C6384D2F9860A8F1E56AF755FC1A5D8C02B 2016-12-06\n\npub   4096R/C4D60F8833789C7CAA44496FD3FFA6613AB10ECE 2016-12-12\nuid\t\tAnother Testuser <schleuder2@example.org>\nsub   4096R/C4D60F8833789C7CAA44496FD3FFA6613AB10ECE 2016-12-12\nsub   4096R/3473864E7188C72EFF6246C2C38DE7E96D4EB747 2016-12-12\n\n")
      expect(mail.list.keys.size).to eql(list_keys.size)
    end

    it 'deletes no key if the argument does not match' do
      mail = Mail.new
      mail.list = create(:list)
      mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
      mail.body = 'ignore me'
      mail.to_s
      list_keys = mail.list.keys

      output = KeywordHandlers::KeyManagement.new(mail: mail, arguments: ['0x0x0x']).delete_key

      expect(output).to eql('No match found for 0x0x0x')
      expect(mail.list.keys.size).to eql(list_keys.size)
    end

    it 'sends error message if no argument is given' do
      mail = Mail.new
      mail.list = create(:list)
      mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
      mail.body = 'ignore me'
      mail.to_s
      list_keys = mail.list.keys

      output = KeywordHandlers::KeyManagement.new(mail: mail, arguments: []).delete_key

      expect(output).to eql("Error: You did not send any arguments for the keyword 'DELETE-KEY'.\n\nOne is required, more are optional, e.g.:\nX-DELETE-KEY: 0xB3D190D5235C74E1907EACFE898F2C91E2E6E1F3\n\nOr, to delete multiple keys at once:\nX-DELETE-KEY: 0xB3D190D5235C74E1907EACFE898F2C91E2E6E1F3 a-subscription@hostname\n\nThe matching keys will be deleted only if the argument matches them distinctly.\n")
      expect(mail.list.keys.size).to eql(list_keys.size)
    end
  end
end
