class CreateMachineAssignments < ActiveRecord::Migration[7.2]
  def change
    create_table :machine_assignments do |t|
      t.references :work_process
      t.references :machine
      t.references :machine_status
      t.timestamps
    end
  end
end
