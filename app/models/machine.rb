class Machine < ApplicationRecord
  belongs_to :machine_type
  belongs_to :company
  has_many :machine_assignments
end
