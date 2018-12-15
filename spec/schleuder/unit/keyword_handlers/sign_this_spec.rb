require 'spec_helper'

describe Schleuder::KeywordHandlers::SignThis do
  let(:keyword_method) { Schleuder::KeywordHandlersRunner::REGISTERED_KEYWORDS[:request]['sign-this'][:method] }
  before(:each) do
  end

  it 'responds to the configured keyword method' do
    instance = KeywordHandlers::SignThis.new(mail: Mail.new, arguments: [])
    expect(instance).to respond_to(keyword_method)
  end

  it 'signs body content if no attachments are present' do
    content = "something\nsomething\nsomething"
    mail = Mail.new
    mail.list = create(:list)
    ENV['GNUPGHOME'] = mail.list.listdir
    mail.body = content
    # Force mail to build its internal structure.
    mail.to_s
    instance = KeywordHandlers::SignThis.new(mail: mail, arguments: [])

    signed_text = instance.send(keyword_method)
    match_string = "BEGIN PGP SIGNED MESSAGE-----\nHash: SHA(256|512)\n\n#{content}\n-----BEGIN PGP SIGNATURE"

    # list.gpg.verify() results in a "Bad Signature".  The sign-this keyword-handler
    # also uses GPGME::Crypto, apparently that makes a difference.
    crypto = GPGME::Crypto.new
    verification_string = ''
    crypto.verify(signed_text) do |sig|
      verification_string = sig.to_s
    end

    expect(signed_text).to match(match_string)
    expect(verification_string).to match('Good signature from D06350440F759BD3')
  end

  it 'signs attachment (even if a body is present)' do
    example_key = File.read('spec/fixtures/example_key.txt')
    expired_key = File.read('spec/fixtures/expired_key.txt')
    mail = Mail.new
    mail.list = create(:list)
    ENV['GNUPGHOME'] = mail.list.listdir
    mail.attachments['example_key.txt'] = { mime_type: 'application/pgp-key',
                                            content: example_key }
    mail.attachments['expired_key.txt'] = { mime_type: 'application/pgp-key',
                                            content: expired_key }
    mail.body = 'body is not relevant'
    # Force mail to build its internal structure.
    mail.to_s
    instance = KeywordHandlers::SignThis.new(mail: mail, arguments: ['arguments', 'are', 'not', 'relevant'])

    parts = instance.send(keyword_method)

    # list.gpg.verify() results in a "Bad Signature".  The sign-this keyword-handler
    # also uses GPGME::Crypto, apparently that makes a difference.
    crypto = GPGME::Crypto.new
    verification_string1 = ''
    crypto.verify(parts[1].body.to_s, {signed_text: example_key}) do |sig|
      verification_string1 = sig.to_s
    end
    verification_string2 = ''
    crypto.verify(parts[2].body.to_s, {signed_text: expired_key}) do |sig|
      verification_string2 = sig.to_s
    end

    expect(parts.size).to be(3)
    expect(parts.map(&:to_s).join).not_to include('relevant')
    expect(parts.first).not_to be_blank
    expect(parts.first).not_to include('translation missing')
    expect(verification_string1).to match('Good signature from D06350440F759BD3')
    expect(verification_string2).to match('Good signature from D06350440F759BD3')
  end
end
