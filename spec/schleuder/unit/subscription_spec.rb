require 'spec_helper'

describe Schleuder::Subscription do
  BOOLEAN_SUBSCRIPTION_ATTRIBUTES =
    [
      :delivery_enabled,
      :admin
  ].freeze

  it 'has a valid factory' do
    subscription = create(:subscription)

    expect(subscription).to be_valid
  end

  it { is_expected.to respond_to :list_id }
  it { is_expected.to respond_to :email }
  it { is_expected.to respond_to :fingerprint }
  it { is_expected.to respond_to :admin }
  it { is_expected.to respond_to :delivery_enabled }

  it 'is invalid when list_id is blank' do
    subscription = build(:subscription, list_id: '')

    expect(subscription).not_to be_valid
    expect(subscription.errors.messages[:list_id]).to be_present
  end

  it 'is invalid when email is nil' do
    list = create(:list)
    subscription = build(:subscription, list_id: list.id, email: nil)

    expect(subscription).not_to be_valid
    expect(subscription.errors.messages[:email]).to include("can't be blank")
  end

   it 'is invalid when email is blank' do
    list = create(:list)
    subscription = build(:subscription, list_id: list.id, email: '')

    expect(subscription).not_to be_valid
    expect(subscription.errors.messages[:email]).to include("can't be blank")
  end

  it 'is invalid when email does not contain an @' do
    list = create(:list)
    subscription = build(:subscription, list_id: list.id, email: 'fooatbar.org')

    expect(subscription).not_to be_valid
    expect(subscription.errors.messages[:email]).to include('is not a valid email address')
  end

  it 'formats email address when email begins with a space' do
    list = create(:list)
    subscription = build(:subscription, list_id: list.id, email: ' foo@bar.org')

    expect(subscription).to be_valid
    expect(subscription.email).to be_eql('foo@bar.org')
    expect(subscription.errors.messages[:email]).to be_blank
  end

  it 'is valid when fingerprint is empty' do
    list = create(:list)
    subscription = build(:subscription, list_id: list.id, fingerprint: '')

    expect(subscription).to be_valid
    expect(subscription.errors.messages[:fingerprint]).to be_blank
  end

  it 'is valid when fingerprint is nil' do
    list = create(:list)
    subscription = build(:subscription, list_id: list.id, fingerprint: nil)

    expect(subscription).to be_valid
    expect(subscription.errors.messages[:fingerprint]).to be_blank
  end

  it 'is invalid when fingerprint contains invalid characters' do
    list = create(:list)
    subscription = build(:subscription, list_id: list.id, fingerprint: '&$$$$123AAA')

    expect(subscription).not_to be_valid
    expect(subscription.errors.messages[:fingerprint]).to include('is not a valid OpenPGP-fingerprint')
  end

  BOOLEAN_SUBSCRIPTION_ATTRIBUTES.each do |subscription_attribute|
    it "is invalid if #{subscription_attribute} is nil" do
      list = create(:list)
      subscription = build(:subscription, list_id: list.id)
      subscription[subscription_attribute] = nil

      expect(subscription).not_to be_valid
      expect(subscription.errors.messages[subscription_attribute]).to include('must be true or false')
    end

    it "is invalid if #{subscription_attribute} is blank" do
      list = create(:list)
      subscription = build(:subscription, list_id: list.id)
      subscription[subscription_attribute] = ''

      expect(subscription).not_to be_valid
      expect(subscription.errors.messages[subscription_attribute]).to include('must be true or false')
    end
  end

  it 'is invalid if the given email is already subscribed for the list' do
    list1 = create(:list)
    list2 = create(:list)
    subscription1 = create(:subscription, list_id: list1.id)
    subscription2 = create(:subscription, list_id: list2.id, email: subscription1.email)
    subscription3 = build(:subscription, email: subscription1.email, list_id: subscription1.list_id)

    expect(subscription1).to be_valid
    expect(subscription2).to be_valid
    expect(subscription3).not_to be_valid
    expect(subscription3.errors[:email]).to eql(['is already subscribed'])
  end

  it 'downcases all letters of an email address' do
    subscription = create(:subscription, email: 'AbcDEF@example.net')

    expect(subscription.email).to eq('abcdef@example.net')
  end

  describe '#fingerprint' do
    it 'transforms the fingerprint to upper case' do
      subscription = Schleuder::Subscription.new(email: 'example@example.org', fingerprint: 'c4d60f8833789c7caa44496fd3ffa6613ab10ece')

      expect(subscription.fingerprint).to eq('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    end
  end

  it 'removes whitespaces and 0x from the fingerprint' do
    fingerprint = '0x 99 991 1000 10'
    subscription = build(:subscription, fingerprint: fingerprint)

    expect(subscription.fingerprint).to eq '99991100010'
  end
end
