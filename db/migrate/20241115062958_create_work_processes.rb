class CreateWorkProcesses < ActiveRecord::Migration[7.2]
  def change
    create_table :work_processes do |t|
      t.references :order
      t.references :process_estimate
      t.references :work_process_status
      t.references :work_process_definition
      t.date :start_date
      t.date :earliest_estimated_completion_date
      t.date :latest_estimated_completion_date
      t.date :factory_estimated_completion_date
      t.date :actual_completion_date
      t.timestamps
    end
  end
end
