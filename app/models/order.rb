class Order < ApplicationRecord
  belongs_to :company
  belongs_to :product_number
  belongs_to :color_number
  has_many :work_processes, -> { ordered }
  has_many :machine_assignments, through: :work_processes
  # 未完了の作業工程を持つ注文を簡単に参照できるアソシエーション
  has_many :incomplete_work_processes, -> { where.not(work_process_status_id: 3) }, class_name: 'WorkProcess'

  # すべての作業工程が完了している注文を取得
  scope :completed, -> {
    left_outer_joins(:incomplete_work_processes)
      .where(work_processes: { id: nil })
  }

  # 少なくとも一つの作業工程が未完了の注文を取得
  scope :incomplete, -> {
    joins(:incomplete_work_processes).distinct
  }

  accepts_nested_attributes_for :work_processes

  # 最新の MachineAssignment を取得するメソッド
  def latest_machine_assignment
    machine_assignments.order(created_at: :desc).first
  end
end
