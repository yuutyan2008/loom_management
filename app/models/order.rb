class Order < ApplicationRecord
  belongs_to :company
  belongs_to :product_number
  belongs_to :color_number
  has_many :work_processes, -> { ordered }

  accepts_nested_attributes_for :work_processes
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


end
