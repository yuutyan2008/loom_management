class Machine < ApplicationRecord
  belongs_to :machine_type
  belongs_to :company
end
