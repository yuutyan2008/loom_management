module SessionsHelper
  # 現在ログインしているユーザーを返す（ログインしていない場合は nil）
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  # ユーザーがログインしているかどうか
  def logged_in?
    !current_user.nil?
  end

  # ユーザーをログインさせる
  def log_in(user)
    session[:user_id] = user.id
  end

  # ユーザーをログアウトさせる
  def log_out
    session.delete(:user_id)
    @current_user = nil
  end
end
