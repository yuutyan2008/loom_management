class MachineAssignment < ApplicationRecord
  belongs_to :machine, optional: true
  belongs_to :machine_status, optional: true
  belongs_to :work_process, optional: true

    # 異なる織機タイプを追加できないようにする

end

