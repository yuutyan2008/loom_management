class WorkProcess < ApplicationRecord
  belongs_to :order
  belongs_to :process_estimate, optional: true # null allow
  belongs_to :work_process_definition
  belongs_to :work_process_status
  has_many :machine_assignments
  # WorkControllerでの関連情報取得簡略化のため、throughを追加
  has_many :machines, through: :machine_assignments

  # 一つの発注で作成されるインスタンスを定義
  def self.initial_processes_list
    [
      {
        work_process_definition_id: 1,
        work_process_status_id: 1
      },
      {
        work_process_definition_id: 2,
        work_process_status_id: 1
      },
      {
        work_process_definition_id: 3,
        work_process_status_id: 1
      },
      {
        work_process_definition_id: 4,
        work_process_status_id: 1
      },
      {
        work_process_definition_id: 5,
        work_process_status_id: 1
      },
     ]
  end
end
