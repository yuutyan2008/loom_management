class CreateMachineStatuses < ActiveRecord::Migration[7.2]
  def change
    create_table :machine_statuses do |t|
      t.string :name
      t.timestamps
    end
  end
end
