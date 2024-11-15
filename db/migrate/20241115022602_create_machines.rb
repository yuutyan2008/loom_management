class CreateMachines < ActiveRecord::Migration[7.2]
  def change
    create_table :machines do |t|
      t.references :machine_type
      t.references :company
      t.string :name
      t.timestamps
    end
  end
end
