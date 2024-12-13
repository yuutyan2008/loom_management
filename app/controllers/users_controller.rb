class UsersController < ApplicationController
  before_action :set_order, only: [ :show, :edit, :update ]
  before_action :require_login, only: [ :show, :edit, :update ]

  def show
  end

  def new
    @user = User.new
    @companies = Company.all
  end

  def create
    @user = User.new(user_params)
    # 会社名に基づいてadminフラグを設定
    company = Company.find_by(id: @user.company_id)
    if company && company.name == "エルトップ"
      @user.admin = true
    else
      @user.admin = false
    end
    if @user.save
      log_in(@user)
      flash[:notice] = "\u30E6\u30FC\u30B6\u30FC\u3092\u767B\u9332\u3057\u307E\u3057\u305F"
      completed_signin(@user)
    else
      @companies = Company.all
      flash.now[:alert] = "\u767B\u9332\u3067\u304D\u307E\u305B\u3093\u3067\u3057\u305F"
      render "new"
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to user_path(@user), notice: "\u30E6\u30FC\u30B6\u30FC\u60C5\u5831\u304C\u66F4\u65B0\u3055\u308C\u307E\u3057\u305F\u3002"
    else
      render :edit, alert: "\u30E6\u30FC\u30B6\u30FC\u60C5\u5831\u304C\u66F4\u65B0\u3067\u304D\u307E\u305B\u3093\u3067\u3057\u305F\u3002"
    end
  end

  private

  def set_order
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :phone_number, :company_id, :password, :password_confirmation)
  end

  def completed_signin(user)
    if user.admin?
      redirect_to admin_root_path
    else
      redirect_to root_path
    end
  end
end
