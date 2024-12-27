class RemoveStartDateFromOrders < ActiveRecord::Migration[7.2]
  def change
    remove_column :orders, :start_date, :date
  end
end
