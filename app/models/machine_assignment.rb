class MachineAssignment < ApplicationRecord
  belongs_to :machine, optional: true
  belongs_to :machine_status
  belongs_to :work_process, optional: true
end
