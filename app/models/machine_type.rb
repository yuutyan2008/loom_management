class MachineType < ApplicationRecord
  has_many :machines
  has_many :process_estimates
end
