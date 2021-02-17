require 'spec_helper'

describe Schleuder::Filters do
  before do
    # Make sure we have the filters loaded, as they will be loaded lazily within the code.
    list = create(:list)
    Schleuder::Filters::Runner.new(list, 'pre').filters
    Schleuder::Filters::Runner.new(list, 'post').filters
  end

  context '.fix_exchange_messages' do
    it 'fixes pgp/mime-messages that were mangled by Exchange' do
      message = Mail.read('spec/fixtures/mails/exchange.eml')
      Schleuder::Filters.fix_exchange_messages(nil, message)

      expect(message[:content_type].content_type).to eql('multipart/encrypted')
    end
    it 'works with a text/plain message' do
      message = Mail.read('spec/fixtures/mails/exchange_no_parts.eml')
      Schleuder::Filters.fix_exchange_messages(nil, message)

      expect(message[:content_type].content_type).to eql('text/plain')
    end
  end

  context '.strip_html_from_alternative' do
    it 'strips HTML-part from multipart/alternative-message that contains ascii-armored PGP-data' do
      list = create(:list)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = 'outside@example.org'
      content = encrypt_string(list, 'blabla')
      mail.text_part = content
      mail.html_part = "<p>#{content}</p>"
      mail.subject = 'test'

      Schleuder::Filters.strip_html_from_alternative(list, mail)

      expect(mail[:content_type].content_type).to eql('multipart/mixed')
      expect(mail.parts.size).to be(1)
      expect(mail.parts.first[:content_type].content_type).to eql('text/plain')
      expect(mail.dynamic_pseudoheaders).to include("Note: This message included an alternating HTML-part that contained\n  PGP-data. The HTML-part was removed to enable parsing the message more\n  properly.")
    end

    it 'does NOT strip HTML-part from multipart/alternative-message that does NOT contain ascii-armored PGP-data' do
      mail = Mail.new
      mail.to = 'schleuder@example.org'
      mail.from = 'outside@example.org'
      content = 'blabla'
      mail.text_part = content
      mail.html_part = "<p>#{content}</p>"
      mail.subject = 'test'

      Schleuder::Filters.strip_html_from_alternative(nil, mail)

      expect(mail[:content_type].content_type).to eql('multipart/alternative')
      expect(mail.parts.size).to be(2)
      expect(mail.parts.first[:content_type].content_type).to eql('text/plain')
      expect(mail.parts.last[:content_type].content_type).to eql('text/html')
      expect(mail.dynamic_pseudoheaders).not_to include('Note: This message included an alternating HTML-part that contained PGP-data. The HTML-part was removed to enable parsing the message more properly.')
    end

    it 'does not choke on nor change a message without Content-Type-header' do
      mail = Mail.new
      mail.to = 'schleuder@example.org'
      mail.from = 'outside@example.org'
      mail.body = 'blabla'
      mail.subject = 'test'

      Schleuder::Filters.strip_html_from_alternative(nil, mail)

      expect(mail[:content_type]).to be_nil
      expect(mail.parts.size).to be(0)
      expect(mail.dynamic_pseudoheaders).not_to include('Note: This message included an alternating HTML-part that contained PGP-data. The HTML-part was removed to enable parsing the message more properly.')
    end
  end

  context '.strip_html_from_alternative_if_keywords_present' do
    it 'strips HTML-part from multipart/alternative-message that contains keywords' do
      list = create(:list)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = 'outside@example.org'
      mail.text_part = content = 'x-resend: someone@example.org\n\nblabla'
      mail.html_part = '<p>x-resend: someone@example.org</p><p>blabla</p>'
      mail.subject = 'test'
      mail.to_s

      Schleuder::Filters.strip_html_from_alternative_if_keywords_present(list, mail)

      expect(mail[:content_type].content_type).to eql('multipart/mixed')
      expect(mail.parts.size).to be(1)
      expect(mail.parts.first[:content_type].content_type).to eql('text/plain')
      expect(mail.dynamic_pseudoheaders).to include("Note: This message included keywords and an alternating HTML-part. The\n  HTML-part was removed to prevent the disclosure of these keywords to third\n  parties.")
    end

    it 'does NOT strip HTML-part from multipart/alternative-message that does NOT contain keywords' do
      list = create(:list)
      mail = Mail.new
      mail.list = list
      mail.to = 'schleuder@example.org'
      mail.from = 'outside@example.org'
      mail.text_part = content = 'Hello someone@example.org,\n\nblabla'
      mail.html_part = '<p>Hello someone@example.org,</p><p>blabla</p>'
      mail.subject = 'test'

      Schleuder::Filters.strip_html_from_alternative_if_keywords_present(list, mail)

      expect(mail[:content_type].content_type).to eql('multipart/alternative')
      expect(mail.parts.size).to be(2)
      expect(mail.parts.first[:content_type].content_type).to eql('text/plain')
      expect(mail.parts.last[:content_type].content_type).to eql('text/html')
      expect(mail.dynamic_pseudoheaders).to be_blank
    end

    it 'does not choke on nor change a message without Content-Type-header' do
      mail = Mail.new
      mail.to = 'schleuder@example.org'
      mail.from = 'outside@example.org'
      mail.body = 'blabla'
      mail.subject = 'test'

      Schleuder::Filters.strip_html_from_alternative_if_keywords_present(nil, mail)

      expect(mail[:content_type]).to be_nil
      expect(mail.parts.size).to be(0)
      expect(mail.dynamic_pseudoheaders).to be_blank
    end
  end
end
