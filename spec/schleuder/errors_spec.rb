require 'spec_helper'

describe 'Errors' do
  def signoff
    t('errors.signoff')
  end

  it '::MessageNotFromAdmin shows sensible string in response to to_s()' do
    expect(Errors::MessageNotFromAdmin.new.to_s).to eql(t('errors.message_not_from_admin') + signoff)
  end

  it '::MessageSenderNotSubscribed shows sensible string in response to to_s()' do
    expect(Errors::MessageSenderNotSubscribed.new.to_s).to eql(t('errors.message_sender_not_subscribed') + signoff)
  end

  it '::MessageUnauthenticated shows sensible string in response to to_s()' do
    expect(Errors::MessageUnauthenticated.new.to_s).to eql(t('errors.message_unauthenticated') + signoff)
  end

  it '::MessageUnencrypted shows sensible string in response to to_s()' do
    expect(Errors::MessageUnencrypted.new.to_s).to eql(t('errors.message_unencrypted') + signoff)
  end

  it '::MessageUnsigned shows sensible string in response to to_s()' do
    expect(Errors::MessageUnsigned.new.to_s).to eql(t('errors.message_unsigned') + signoff)
  end

  it '::LoadingListSettingsFailed shows sensible string in response to to_s()' do
    expect(Errors::LoadingListSettingsFailed.new.to_s).to eql(t('errors.loading_list_settings_failed', config_file: ENV['SCHLEUDER_LIST_DEFAULTS']) + signoff)
  end

  it '::DecryptionFailed shows sensible string in response to to_s()' do
    list = create(:list)
    expect(Errors::DecryptionFailed.new(list).to_s).to eql(t('errors.decryption_failed', key: list.key.to_s, email: list.sendkey_address) + signoff)
  end

  it '::KeyAdduidFailed shows sensible string in response to to_s()' do
    expect(Errors::KeyAdduidFailed.new('bla').to_s).to eql(t('errors.key_adduid_failed', errmsg: 'bla') + signoff)
  end

  it '::KeyGenerationFailed shows sensible string in response to to_s()' do
    list = create(:list)
    expect(Errors::KeyGenerationFailed.new(list.listdir, list.email).to_s).to eql(t('errors.key_generation_failed', listdir: list.listdir, listname: list.email) + signoff)
  end

  it '::KeywordAdminOnly shows sensible string in response to to_s()' do
    expect(Errors::KeywordAdminOnly.new('bla').to_s).to eql(t('errors.keyword_admin_only', keyword: 'bla') + signoff)
  end

  it '::ListNotFound shows sensible string in response to to_s()' do
    list = create(:list)
    expect(Errors::ListNotFound.new(list.email).to_s).to eql(t('errors.list_not_found', email: list.email) + signoff)
  end

  it '::ListdirProblem shows sensible string in response to to_s()' do
    list = create(:list)
    expect(Errors::ListdirProblem.new(list.listdir, 'not_empty').to_s).to eql(t('errors.listdir_problem.message', dir: list.listdir, problem: t('errors.listdir_problem.not_empty')) + signoff)
  end

  it '::MessageEmpty shows sensible string in response to to_s()' do
    list = create(:list)
    expect(Errors::MessageEmpty.new(list).to_s).to eql(t('errors.message_empty', request_address: list.request_address) + signoff)
  end

  it '::MessageTooBig shows sensible string in response to to_s()' do
    list = create(:list)
    expect(Errors::MessageTooBig.new(list).to_s).to eql(t('errors.message_too_big', allowed_size: list.max_message_size_kb) + signoff)
  end

  it '::TooManyKeys shows sensible string in response to to_s()' do
    list = create(:list)
    expect(Errors::TooManyKeys.new(list.listdir, list.email).to_s).to eql(t('errors.too_many_keys', listdir: list.listdir, listname: list.email) + signoff)
  end
end

