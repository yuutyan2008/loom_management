class HomeController < ApplicationController
  before_action :require_login, only: [:index]

  def index
    @company = current_user.company
    if @company.orders.exists?
      @orders = @company.orders
    else
      @orders = []
      @no_orders_message = "現在受注している商品はありません"
    end
  end
end
