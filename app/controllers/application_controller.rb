class ApplicationController < ActionController::Base
  include SessionsHelper

  def manifest
    render file: 'app/views/pwa/manifest.json.erb',
           content_type: 'application/json',
           layout: false
  end

  private

  def require_login
    unless logged_in?
      flash[:alert] = "ログインが必要です。"
      redirect_to login_path
    end
  end
end
