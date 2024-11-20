class Machine < ApplicationRecord
  belongs_to :machine_type
  belongs_to :company
  has_many :machine_assignments
  has_many :work_processes, through: :machine_assignments
end
