FactoryBot.define do
  factory :user do
    name { "Test User" }
    email { "testuser@example.com" }
    phone_number { "1234567890" }
    password { "password" }
    password_confirmation { "password" }
    admin { false }
    association :company
  end
end

