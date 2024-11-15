class CreateWorkProcessStatuses < ActiveRecord::Migration[7.2]
  def change
    create_table :work_process_statuses do |t|
      t.integer :name
      t.timestamps
    end
  end
end
