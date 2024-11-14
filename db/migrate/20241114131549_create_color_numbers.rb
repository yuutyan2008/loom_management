class CreateColorNumbers < ActiveRecord::Migration[7.2]
  def change
    create_table :color_numbers do |t|
      t.string :color_code
      t.timestamps
    end
  end
end
