FactoryBot.define do
  factory :list do
    sequence(:email) {|n| "list#{n}@example.org" }
    fingerprint { '59C71FB38AEE22E091C78259D06350440F759BD3' }
    log_level { 'warn' }
    subject_prefix { nil }
    subject_prefix_in { nil }
    subject_prefix_out { nil }
    openpgp_header_preference { 'signencrypt' }
    internal_footer { nil }
    public_footer { nil }
    headers_to_meta { ['from', 'to', 'cc', 'date', 'sig', 'enc'] }
    bounces_drop_on_headers { { 'x-spam-flag' => true } }
    keywords_admin_only { ['subscribe', 'unsubscribe', 'delete-key'] }
    keywords_admin_notify { ['add-key'] }
    send_encrypted_only { true }
    receive_encrypted_only { false }
    receive_signed_only { false }
    receive_authenticated_only { false }
    receive_from_subscribed_emailaddresses_only { false }
    receive_admin_only { false }
    keep_msgid { true }
    bounces_drop_all { false }
    bounces_notify_admins { true }
    deliver_selfsent { true }
    include_autocrypt_header { true }
    include_list_headers { true }
    include_openpgp_header { true }
    max_message_size_kb { 10240 }
    language { 'en' }
    forward_all_incoming_to_admins { false }
    logfiles_to_keep { 2 }
    after(:build) do |list|
      FileUtils.mkdir_p(list.listdir)
      gpghome_upstream = File.join 'spec', 'gnupg'
      FileUtils.cp_r Dir["#{gpghome_upstream}/{private*,*.gpg,.*migrated}"], list.listdir
    end

    trait :with_one_subscription do
      after(:build) do |list|
        create(:subscription)
      end
    end

    factory :list_with_one_subscription, traits: [:with_one_subscription]
  end
end
