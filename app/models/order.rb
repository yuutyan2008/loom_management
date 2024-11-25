class Order < ApplicationRecord
  belongs_to :company
  belongs_to :product_number
  belongs_to :color_number
  has_many :work_processes, -> { ordered }
end
