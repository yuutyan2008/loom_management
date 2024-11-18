class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.references :company
      t.references :product_number
      t.references :color_number
      t.integer :roll_count
      t.integer :quantity
      t.date :start_date
      t.timestamps
    end
  end
end
