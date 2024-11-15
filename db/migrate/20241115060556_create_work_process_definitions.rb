class CreateWorkProcessDefinitions < ActiveRecord::Migration[7.2]
  def change
    create_table :work_process_definitions do |t|
      t.integer :name
      t.integer :sequence
      t.timestamps
    end
  end
end
