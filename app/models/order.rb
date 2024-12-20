class Order < ApplicationRecord
  belongs_to :company
  belongs_to :product_number
  belongs_to :color_number
  has_many :work_processes, -> { ordered }
  has_many :machine_assignments, through: :work_processes

  # 未完了の作業工程を持つ注文を簡単に参照できるアソシエーション
  has_many :incomplete_work_processes, -> { where.not(work_process_status_id: 3) }, class_name: 'WorkProcess'

  # accepts_nested_attributes_for :machine_assignments

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
  # 検索のスコープ
  # 会社名
  scope :search_by_company, ->(company_id) {
    joins(:company).where(company: { id: company_id }) if company_id.present?
  }

  # 品番
  scope :search_by_product_number, ->(product_number_id) {
    joins(:product_number).where(product_number: { id: product_number_id }) if product_number_id.present?
  }

  # 色番
  scope :search_by_color_number, ->(color_number_id) {
    joins(:color_number).where(color_number: { id: color_number_id }) if color_number_id.present?
  }

  # 現在の工程
  scope :search_by_work_process_definitios, ->(work_process_definition_id) {
    joins(:work_processes).where(work_processes: { work_process_definition_id: work_process_definition_id }) if work_process_definition_id.present?
  }

  # 注文が1週間以内に作成されたかを判定するメソッド
  def recent?
    created_at >= 1.weeks.ago
  end
end
