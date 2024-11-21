class UsersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update]
  before_action :require_login, only: [:show, :edit, :update]

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
      flash[:notice] = 'ユーザーを登録しました'
      completed_signin(@user)
    else
      @companies = Company.all
      flash.now[:alert] = '登録できませんでした'
      render 'new'
    end
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to user_path(@user), notice: 'ユーザー情報が更新されました。'
    else
      render :edit
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
      redirect_to admin_orders_path
    else
      redirect_to root_path
    end
  end
end
