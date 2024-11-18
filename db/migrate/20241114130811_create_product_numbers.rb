class CreateProductNumbers < ActiveRecord::Migration[7.2]
  def change
    create_table :product_numbers do |t|
      t.string :number
      t.timestamps
    end
  end
end
