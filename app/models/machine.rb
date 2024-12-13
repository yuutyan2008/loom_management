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

  # 会社名
  scope :search_by_company, ->(company_id) {
    joins(:company).where(company: { id: company_id }) if company_id.present?
  }

  # 織機
  scope :search_by_machine, ->(machine_id) { where(id: machine_id) if machine_id.present? }

  # 色番
  scope :search_by_product_number, ->(product_number_id) {
    joins(machine_assignments: { work_process: :order })
    .where(orders: { product_number_id: product_number_id }) if product_number_id.present?
  }

  # 現在の工程
  scope :search_by_work_process_definitios, ->(work_process_definition_id) {
    joins(:work_processes).where(work_processes: { work_process_definition_id: work_process_definition_id }) if work_process_definition_id.present?
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
