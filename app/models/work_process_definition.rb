class WorkProcessDefinition < ApplicationRecord
  has_many :process_estimates
  has_many :work_processes
end
