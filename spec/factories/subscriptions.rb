FactoryBot.define do
  factory :subscription do
    list
    sequence(:email) {|n| "subscription#{n}@example.org" }
    fingerprint { '129A74AD5317457F9E502844A39C61B32003A8D8' }
    admin { true }
    delivery_enabled { true }
  end
end
