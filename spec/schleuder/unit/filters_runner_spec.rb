require 'spec_helper'

module Schleuder::Filters
  def self.dummy(list, mail)
    nil
  end

  def self.stop(list, mail)
    nil
  end
end

describe Schleuder::Filters::Runner do
  let(:list) do
    # setup the list with an admin that can be notified
    list = create(:list, send_encrypted_only: false)
    list.subscribe('schleuder@example.org', nil, true)
    list
  end
  let(:pre_filters) { Schleuder::Filters::Runner.new(list, 'pre') }
  let(:post_filters){ Schleuder::Filters::Runner.new(list, 'post') }

  it { expect(pre_filters).to respond_to :run }

  context '#run' do
    it 'runs the filters' do
      mail = Mail.new
      expect(Schleuder::Filters).to receive(:dummy).once
      expect(Schleuder::Filters).to_not receive(:stop)
      expect(pre_filters).to receive(:filters).and_return(['dummy'])
      expect(pre_filters.run(mail)).to be_nil
    end

    it 'stops on a StandardError and returns error' do
      mail = Mail.new
      error = StandardError.new
      expect(Schleuder::Filters).to_not receive(:dummy)
      expect(Schleuder::Filters).to receive(:stop).once { error }
      expect(pre_filters).to receive(:filters).and_return(['stop', 'dummy'])
      expect(pre_filters.run(mail)).to eql(error)
      expect(Mail::TestMailer.deliveries.first).to be_nil
    end
    it 'stops on a StandardError and will notify admins' do
      mail = Mail.new
      error = StandardError.new
      pre_filters.list.bounces_drop_all = true
      expect(Schleuder::Filters).to_not receive(:dummy)
      expect(Schleuder::Filters).to receive(:stop).once { error }
      expect(pre_filters).to receive(:filters).and_return(['stop', 'dummy'])
      expect(pre_filters.run(mail)).to be_nil
      expect(Mail::TestMailer.deliveries.first).to_not be_nil
    end
    it 'stops on a StandardError and will notify on headers match' do
      mail = Mail.new
      error = StandardError.new
      mail['X-SPAM-FLAG'] = 'TRUE'
      expect(Schleuder::Filters).to_not receive(:dummy)
      expect(Schleuder::Filters).to receive(:stop).once { error }
      expect(pre_filters).to receive(:filters).and_return(['stop', 'dummy'])
      expect(pre_filters.run(mail)).to be_nil
      expect(Mail::TestMailer.deliveries.first).to_not be_nil
    end
  end
  context 'loading filters' do
    it 'loads filters from built-in filters_dir sorts them' do
      Schleuder::Conf.instance.config['filters_dir'] = File.join(Dir.pwd, 'spec/fixtures/no_filters')
      expect(pre_filters.filters).to eq [
        'forward_bounce_to_admins',
        'forward_all_incoming_to_admins',
        'send_key',
        'fix_exchange_messages',
        'strip_html_from_alternative'
      ]
      expect(post_filters.filters).to eq [
        'request',
        'max_message_size',
        'forward_to_owner',
        'receive_admin_only',
        'receive_authenticated_only',
        'receive_signed_only',
        'receive_encrypted_only',
        'receive_from_subscribed_emailaddresses_only',
        'strip_html_from_alternative_if_keywords_present'
      ]
    end
    it 'loads custom filters from filters_dir and sorts them in, ignores filter not following convention' do
      Schleuder::Conf.instance.config['filters_dir'] = File.join(Dir.pwd, 'spec/fixtures/filters')
      expect(pre_filters.filters).to eq [
        'forward_bounce_to_admins',
        'forward_all_incoming_to_admins',
        'example',
        'send_key',
        'fix_exchange_messages',
        'strip_html_from_alternative'
      ]
      expect(post_filters.filters).to eq [
        'request',
        'max_message_size',
        'forward_to_owner',
        'receive_admin_only',
        'receive_authenticated_only',
        'receive_signed_only',
        'receive_encrypted_only',
        'post_example',
        'receive_from_subscribed_emailaddresses_only',
        'strip_html_from_alternative_if_keywords_present'
      ]
    end
    it 'loads custom filters from filters_dir and sorts them in with missing dir' do
      Schleuder::Conf.instance.config['filters_dir'] = File.join(Dir.pwd, 'spec/fixtures/filters_without_pre')
      expect(pre_filters.filters).to eq [
        'forward_bounce_to_admins',
        'forward_all_incoming_to_admins',
        'send_key',
        'fix_exchange_messages',
        'strip_html_from_alternative'
      ]
      expect(post_filters.filters).to eq [
        'post_example',
        'request',
        'max_message_size',
        'forward_to_owner',
        'receive_admin_only',
        'receive_authenticated_only',
        'receive_signed_only',
        'receive_encrypted_only',
        'receive_from_subscribed_emailaddresses_only',
        'strip_html_from_alternative_if_keywords_present'
      ]
    end
    it 'loads custom filters from filters_dir even with non-2-digit priority' do
      Schleuder::Conf.instance.config['filters_dir'] = File.join(Dir.pwd, 'spec/fixtures/more_filters')
      expect(pre_filters.filters).to eq [
        'early_example',
        'forward_bounce_to_admins',
        'forward_all_incoming_to_admins',
        'example',
        'send_key',
        'fix_exchange_messages',
        'strip_html_from_alternative',
        'late_example'
      ]
      expect(post_filters.filters).to eq [
        'request',
        'max_message_size',
        'forward_to_owner',
        'receive_admin_only',
        'receive_authenticated_only',
        'receive_signed_only',
        'receive_encrypted_only',
        'receive_from_subscribed_emailaddresses_only',
        'strip_html_from_alternative_if_keywords_present',
      ]
    end
  end
end
