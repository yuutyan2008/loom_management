class MachineAssignment < ApplicationRecord
  belongs_to :machine
  belongs_to :machine_status
end
