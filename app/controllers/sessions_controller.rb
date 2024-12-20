class SessionsController < ApplicationController
  def new
  end

  def create
    email = params[:session][:email].downcase
    password = params[:session][:password]
    user = User.find_by(email: email)

    if user
      if user.authenticate(password)
        log_in(user)
        completed_login(user)
      else
        flash.now[:alert] = 'パスワードが間違っています'
        render 'new'
      end
    else
      flash.now[:alert] = 'メールアドレスが間違っています'
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
      redirect_to admin_root_path
    else
      redirect_to root_path
    end
    flash[:notice] = 'ログインしました'
  end
end
