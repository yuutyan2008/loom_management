class ProcessEstimate < ApplicationRecord
  belongs_to :machine_type
  belongs_to :work_process_definition
end
