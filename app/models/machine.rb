class Machine < ApplicationRecord
  belongs_to :machine_type
  belongs_to :company
  has_many :machine_assignments
  # WorkControllerでの関連情報取得簡略化のため、throughを追加
  has_many :work_processes, through: :machine_assignments

  scope :machine_associations, -> {
    includes(
      :machine_assignments,
      machine_assignments: [:machine_status],
      work_processes: {
        work_process_status: {},
        work_process_definition: {},
        order: [:company, :product_number, :color_number]
      }
    )
  }

  # 特定のIDを持つ機械を取得するクラスメソッド
  def self.find_with_associations(id)
    machine_associations.find_by(id: id)
  end

  # 以下はWorkProcessモデルのデータを取得する方法
  # 最新の工程を取得するメソッドを定義
  def latest_work_process
    work_processes.order(created_at: :desc).first
  end
  # 最新の工程の状況を取得するメソッドを定義
  def latest_work_process_status
    latest_work_process&.work_process_status
  end
  # 最新の完成予定日を取得するメソッド
  def latest_factory_estimated_completion_date
    latest_work_process&.factory_estimated_completion_date
  end

  # 以下はMachineAssignmentモデルのデータを取得する方法
  # 最新のMachineAssignmentを取得するメソッドを定義
  def latest_machine_assignment
    machine_assignments.order(created_at: :desc).first
  end
  # 最新のMachineStatusを取得するメソッドを定義
  def latest_machine_status
    latest_machine_assignment&.machine_status
  end
end
