FactoryBot.define do
  factory :machine do
    name { "Test Machine" }

    association :machine_type
    association :company
  end
end
