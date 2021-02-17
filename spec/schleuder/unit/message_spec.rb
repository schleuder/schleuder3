require 'spec_helper'

describe Mail::Message do
  it "doesn't change the order of mime-parts" do
    text_part = Mail::Part.new
    text_part.body = 'This is text'
    image_part = Mail::Part.new
    image_part.content_type = 'image/png'
    image_part.content_disposition = 'attachment; filename=spec.png'
    message = Mail.new
    message.parts << image_part
    message.parts << text_part

    # This triggers the sorting.
    message.to_s

    expect(message.parts.first.mime_type).to eql('image/png')
    expect(message.parts.last.mime_type).to eql('text/plain')
  end

  # TODO: test message with "null" address ("<>") as Return-Path. I couldn't
  # bring Mail to generate such a message, yet.
  
  it 'recognizes a message sent to listname-bounce@hostname as automated message' do
    list = create(:list)
    mail = Mail.new
    # Trigger the setting of mandatory headers.
    mail.to_s
    mail = Mail.create_message_to_list(mail.to_s, 'something-bounce@localhost', list).setup

    expect(mail.automated_message?).to be(true)
  end

  it 'recognizes bounce message subject using the bounce_email gem' do
    list = create(:list)
    mail = Mail.new
    mail.subject = 'Undelivered Mail Returned to Sender'
    mail = Mail.create_message_to_list(mail.to_s, 'something@localhost', list).setup

    expect(mail.automated_message?).to be(true)
  end
  
  Dir.glob('spec/fixtures/mails/not_bounces/*') do |filename|
    it "does not misclassify normal message #{filename} as bounce" do
      list = create(:list)
      mail = Mail.new(File.read(filename))
      mail = Mail.create_message_to_list(mail.to_s, 'something@localhost', list).setup
    
      expect(mail.automated_message?).to be(false)
    end
  end

  Dir.glob('spec/fixtures/mails/bounces/*') do |filename|
    it "does not misclassify bounce #{filename} as normal message" do
      list = create(:list)
      mail = Mail.new(File.read(filename))
      mail = Mail.create_message_to_list(mail.to_s, 'something@localhost', list).setup
    
      expect(mail.automated_message?).to be(true)
    end
  end

  it "recognizes a cron message with 'Auto-Submitted'-header NOT as automated message" do
    list = create(:list)
    mail = Mail.new
    mail.header['Auto-Submitted'] = 'yes'
    mail.header['X-Cron-Env'] = '<MAILTO=root>'
    # Trigger the setting of mandatory headers.
    mail.to_s
    mail = Mail.create_message_to_list(mail.to_s, 'something@localhost', list).setup

    expect(mail.automated_message?).to be(false)
  end

  it "recognizes a Jenkins message with 'Auto-Submitted'-header NOT as automated message" do
    list = create(:list)
    mail = Mail.new
    mail.header['Auto-submitted'] = 'auto-generated'
    mail.header['X-Jenkins-Job'] = 'test_Tails_ISO_stable'
    # Trigger the setting of mandatory headers.
    mail.to_s
    mail = Mail.create_message_to_list(mail.to_s, 'something@localhost', list).setup

    expect(mail.automated_message?).to be(false)
  end

  # https://0xacab.org/schleuder/schleuder/issues/248
  it "recognizes a sudo message with 'Auto-Submitted'-header NOT as automated message" do
    list = create(:list)
    mail = Mail.new
    mail.header['Auto-submitted'] = 'auto-generated'
    mail.subject = '*** SECURITY information for host.example.com ***'
    # Trigger the setting of mandatory headers.
    mail.to_s
    mail = Mail.create_message_to_list(mail.to_s, 'something@localhost', list).setup

    expect(mail.automated_message?).to be(false)
  end

  context '#add_subject_prefix!' do
    it 'adds a configured subject prefix' do
      list = create(:list)
      list.subject_prefix = '[prefix]'
      list.subscribe('admin@example.org',nil,true)
      mail = Mail.new
      mail.from 'someone@example.org'
      mail.to list.email
      mail.text_part = 'blabla'
      mail.subject = 'test'

      message = Mail.create_message_to_list(mail.to_s, list.email, list).setup
      message.add_subject_prefix!

      expect(message.subject).to eql('[prefix] test')
    end
    it 'adds a configured subject prefix without subject' do
      list = create(:list)
      list.subject_prefix = '[prefix]'
      list.subscribe('admin@example.org',nil,true)
      mail = Mail.new
      mail.from 'someone@example.org'
      mail.to list.email
      mail.text_part = 'blabla'

      message = Mail.create_message_to_list(mail.to_s, list.email, list).setup
      message.add_subject_prefix!

      expect(message.subject).to eql('[prefix]')
    end
    it 'does not add a subject prefix if already present' do
      list = create(:list)
      list.subject_prefix = '[prefix]'
      list.subscribe('admin@example.org',nil,true)
      mail = Mail.new
      mail.from 'someone@example.org'
      mail.to list.email
      mail.text_part = 'blabla'
      mail.subject = 'Re: [prefix] test'

      message = Mail.create_message_to_list(mail.to_s, list.email, list).setup
      message.add_subject_prefix!

      expect(message.subject).to eql('Re: [prefix] test')
    end
  end

  it 'adds list#public_footer as last mime-part without changing its value' do
    footer = "\n\n-- \nblabla\n  blabla\n  "
    list = create(:list)
    list.public_footer = footer
    mail = Mail.new
    mail.body = 'blabla'
    mail.list = list
    mail.add_public_footer!

    expect(mail.parts.last.body.to_s).to eql(footer)
  end

  it 'adds list#internal_footer as last mime-part without changing its value' do
    footer = "\n\n-- \nblabla\n  blabla\n  "
    list = create(:list)
    list.internal_footer = footer
    mail = Mail.new
    mail.body = 'blabla'
    mail.list = list
    mail.add_internal_footer!

    expect(mail.parts.last.body.to_s).to eql(footer)
  end

  context 'makes a pseudo header' do
    it 'with key / value' do
      mail = Mail.new
      ph = mail.make_pseudoheader('notice','some value')
      expect(ph).to eql('Notice: some value')
    end

    it 'without value' do
      mail = Mail.new
      ph = mail.make_pseudoheader(:key,nil)
      expect(ph).to eql('Key: ')
    end

    it 'with empty value' do
      mail = Mail.new
      ph = mail.make_pseudoheader(:key,'')
      expect(ph).to eql('Key: ')
    end

    it 'that is getting wrapped' do
      mail = Mail.new
      ph = mail.make_pseudoheader('notice','adds list#public_footer as last mime-part without changing its value adds list#public_footer as last mime-part without changing its value')
      expect(ph).to eql("Notice: adds list#public_footer as last mime-part without changing its value\n  adds list#public_footer as last mime-part without changing its value")
      expect(ph.split("\n")).to all( satisfy{|l| l.length <= 78 })
    end

    it 'that multiline are getting wrapped' do
      mail = Mail.new
      ph = mail.make_pseudoheader('notice',"adds list#public_footer as last mime-part\nwithout changing its value adds list#public_footer as last mime-part without changing its value")
      expect(ph).to eql("Notice: adds list#public_footer as last mime-part\n  without changing its value adds list#public_footer as last mime-part without\n  changing its value")
      expect(ph.split("\n")).to all( satisfy{|l| l.length <= 78 })
    end
    it 'that single multiline are getting indented' do
      mail = Mail.new
      ph = mail.make_pseudoheader('notice',"on line 1\non line 2 but indented")
      expect(ph).to eql("Notice: on line 1\n  on line 2 but indented")
      expect(ph.split("\n")).to all( satisfy{|l| l.length <= 78 })
    end
    it 'that a line with less than 76 gets wrapped' do
      mail = Mail.new
      ph = mail.make_pseudoheader('keylongerthan8', 'afafa afafaf' * 6) # message is 72 long
      expect(ph).to eql("Keylongerthan8: afafa afafafafafa afafafafafa afafafafafa afafafafafa\n  afafafafafa afafaf")
      expect(ph.split("\n")).to all( satisfy{|l| l.length <= 78 })
    end
    it 'that a multiline with less than 76 get wrapped correctly on the first line' do
      mail = Mail.new
      ph = mail.make_pseudoheader('keylongerthan8', ('afafa afafaf' * 6)+"\nbla bla newline")
      expect(ph).to eql("Keylongerthan8: afafa afafafafafa afafafafafa afafafafafa afafafafafa\n  afafafafafa afafaf\n  bla bla newline")
      expect(ph.split("\n")).to all( satisfy{|l| l.length <= 78 })
    end
    it 'that a multiline with less than 76 get wrapped correctly on the first line and the following lines' do
      mail = Mail.new
      ph = mail.make_pseudoheader('keylongerthan8', ('afafa afafaf' * 6)+"\nbla bla newline"+('afafa afafaf' * 6))
      expect(ph).to eql("Keylongerthan8: afafa afafafafafa afafafafafa afafafafafa afafafafafa\n  afafafafafa afafaf\n  bla bla newlineafafa afafafafafa afafafafafa afafafafafa afafafafafa\n  afafafafafa afafaf")
      expect(ph.split("\n")).to all( satisfy{|l| l.length <= 78 })
    end
  end

  context '.keywords' do
    it 'stops looking for keywords when a blank line that is not followed by another keyword is met' do
      string = "x-something: bla\nx-somethingelse: ok\n\nsomething\nx-toolate: tralafiti\n"
      m = Mail.new
      m.body = string
      m.to_s

      keywords = m.keywords

      expect(keywords).to eql([['something', ['bla']], ['somethingelse', ['ok']]])
      expect(m.body.to_s).to eql("something\nx-toolate: tralafiti\n")
    end

    it 'reads multiple lines as keyword arguments' do
      string = "x-something: first\nsecond\nthird\nx-somethingelse: ok\n\ntralafiti\n"
      m = Mail.new
      m.body = string
      m.to_s

      keywords = m.keywords

      expect(keywords).to eql([['something', ['first', 'second', 'third']], ['somethingelse', ['ok']]])
      expect(m.body.to_s).to eql("tralafiti\n")
    end

    it 'takes the whole rest of the body as keyword argument if blank lines are present' do
      string = "x-something: first\nsecond\nthird\nok\ntralafiti\n"
      m = Mail.new
      m.body = string
      m.to_s

      keywords = m.keywords

      expect(keywords).to eql([['something', ['first', 'second', 'third', 'ok', 'tralafiti']]])
      expect(m.body.to_s).to eql('')
    end

    it 'drops empty lines in keyword arguments parsing' do
      string = "x-something: first\nthird\n\nx-somethingelse: ok\n\ntralafiti\n"
      m = Mail.new
      m.body = string
      m.to_s

      keywords = m.keywords

      expect(keywords).to eql([['something', ['first', 'third']], ['somethingelse', ['ok']]])
      expect(m.body.to_s).to eql("tralafiti\n")
    end

    it 'drops multiple empty lines between keywords and content' do
      string = "x-something: first\nthird\nx-somethingelse: ok\n\n\n\ntralafiti\n"
      m = Mail.new
      m.body = string
      m.to_s

      keywords = m.keywords

      expect(keywords).to eql([['something', ['first', 'third']], ['somethingelse', ['ok']]])
      expect(m.body.to_s).to eql("tralafiti\n")
    end

    it 'splits lines into words and downcases them in keyword arguments' do
      string = "x-something: first\nSECOND     end\nthird\nx-somethingelse: ok\n\ntralafiti\n"
      m = Mail.new
      m.body = string
      m.to_s

      keywords = m.keywords

      expect(keywords).to eql([['something', ['first', 'second', 'end', 'third']], ['somethingelse', ['ok']]])
      expect(m.body.to_s).to eql("tralafiti\n")
    end
  end
end

