class CreateProcessEstimates < ActiveRecord::Migration[7.2]
  def change
    create_table :process_estimates do |t|
      t.references :work_process_definition
      t.references :machine_type
      t.string :earliest_completion_estimate
      t.string :latest_completion_estimate
      t.date :update_date
      t.timestamps
    end
  end
end
