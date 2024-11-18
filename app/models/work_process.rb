class WorkProcess < ApplicationRecord
  belongs_to :order
  belongs_to :process_estimate
  belongs_to :work_process_definition
  belongs_to :work_process_status
  has_many :machine_assignments
end
