class User::HomeController < ApplicationController
  def index
    # ログイン機能が未実装のため、すべての受注を取得
    @orders = Order.all
  end
end
