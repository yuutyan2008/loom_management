class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      log_in(user)
      completed_login(user)
    else
      flash.now[:alert] = '登録できませんでした'
      render 'new'
    end
  end

  def destroy
    session[:user_id] = nil
    @current_user = nil
    flash[:notice] = 'ログアウトしました'
    redirect_to login_path
  end

  private

  def completed_login(user)
    if user.admin?
      redirect_to admin_orders_path
      flash[:notice] = 'ログインしました'
    else
      redirect_to root_path
      flash[:notice] = 'ログインしました'
    end
  end
end
