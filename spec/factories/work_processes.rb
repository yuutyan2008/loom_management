# spec/factories/work_processes.rb
FactoryBot.define do
  factory :work_process do
    start_date { Date.today }
    earliest_estimated_completion_date { Date.today + 10 }
    latest_estimated_completion_date { Date.today + 15 }
    actual_completion_date { nil }
    work_process_status { association :work_process_status, name: "作業中" }
    work_process_definition { association :work_process_definition, name: "製織", sequence: 1 }
    order { association :order }
    process_estimate { association :process_estimate }
  end

  factory :work_process_status do
    name { "作業中" }
  end

  factory :work_process_definition do
    name { "製織" }
    sequence(:sequence) { |n| n }
  end

  factory :process_estimate do
    machine_type { association :machine_type }
    work_process_definition { association :work_process_definition }

    # work_process_definition_idごとの値を動的に設定
    earliest_completion_estimate do
      case work_process_definition_id
      when 1 then 90
      when 2 then 14
      when 3 then 7
      when 4 then 25
      when 5 then 4
      end
    end

    latest_completion_estimate do
      case work_process_definition_id
      when 1 then 150
      when 2 then 21
      when 3 then 14
      when 4 then 30
      when 5 then 5
      end
    end

  end

  factory :machine_type do
    name { "ドビー" }
  end

  factory :order do
    company { association :company }
    product_number { association :product_number }
    color_number { association :color_number }
    roll_count { 10 }
    quantity { 100 }
  end

  factory :company do
    name { "Test Company" }
  end

  factory :product_number do
    number { "PN-12345" }
  end

  factory :color_number do
    color_code { "#FFFFFF" }
  end
end
