class Order < ApplicationRecord
  belongs_to :company
  belongs_to :product_number
  belongs_to :color_number
  has_many :work_processes, -> { ordered }
  has_many :machine_assignments, through: :work_processes

  accepts_nested_attributes_for :work_processes

  # 最新の MachineAssignment を取得するメソッド
  def latest_machine_assignment
    machine_assignments.order(created_at: :desc).first
  end
end
