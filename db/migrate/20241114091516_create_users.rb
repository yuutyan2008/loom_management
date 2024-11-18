class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :phone_number
      t.references :company
      t.boolean :admin
      t.timestamps
    end
  end
end
