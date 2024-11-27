class ProcessEstimate < ApplicationRecord
  belongs_to :machine_type
  belongs_to :work_process_definition
  has_many :work_processes

  # ナレッジの計算処理の定義
  # def self.initial_estimates_list
  #   # ドビーならid=1
  #   if type_check_id == 1
  #     [{
  #       work_process_definition_id: 1,
  #       earliest_completion_estimate: 90,
  #       latest_completion_estimate: 150
  #     },
  #     {
  #       work_process_definition_id: 2,
  #       earliest_completion_estimate: 14,
  #       latest_completion_estimate: 21
  #     },
  #     {
  #       work_process_definition_id: 3,
  #       earliest_completion_estimate: 7,
  #       latest_completion_estimate: 14
  #     },
  #     {
  #       work_process_definition_id: 4,
  #       earliest_completion_estimate: 25,
  #       latest_completion_estimate: 30
  #     },
  #     {
  #       work_process_definition_id: 5,
  #       earliest_completion_estimate: 4,
  #       latest_completion_estimate: 5
  #     }]
  # end

  # end
end
