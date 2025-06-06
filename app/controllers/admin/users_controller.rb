class Admin::UsersController < ApplicationController
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]
  before_action :require_login, only: [ :show, :edit, :update, :destroy ]

  def index
    @users = User.where.not(id: current_user.id)
  end

  def show
  end

  def show_myaccount
    @user = current_user
  end

  def new
    @user = User.new
    @companies = Company.all
  end

  def create
    # user_paramsに:company_idと:new_company_nameが含まれます
    @user = User.new(user_params.except(:new_company_name))

    # パスワードを自動生成
    generated_password = SecureRandom.urlsafe_base64(12)
    @user.password = generated_password
    @user.password_confirmation = generated_password

    # メールアドレスが空の場合、仮のメールアドレスを生成
    if @user.email.blank?
      # 仮のメールアドレスを生成。ユニーク性を確保するためにランダムな文字列を使用
      placeholder_email = "user_#{SecureRandom.hex(4)}@example.com"
      @user.email = placeholder_email
    end

    # 会社名に基づいてadminフラグを設定
    company = Company.find_by(id: @user.company_id)
    if company && company.name == "エルトップ"
      @user.admin = true
    else
      @user.admin = false
    end

    # 新しい会社名が入力されている場合、会社を作成してユーザーに関連付ける
    new_company_name = user_params[:new_company_name]
    if new_company_name.present?
      # 既に同じ名前の会社が存在する場合は取得し、なければ新規作成
      company = Company.find_or_create_by(name: new_company_name)
      @user.company_id = company.id
    end

    # バリデーション: 会社IDまたは新しい会社名のいずれかが必須
    if @user.company_id.blank? && new_company_name.blank?
      @user.errors.add(:base, "既存の会社を選択するか、新しい会社名を入力してください。")
    end

    if @user.save
      # フラッシュメッセージにメールアドレスとパスワードを設定
      flash[:notice] = "ユーザーが作成されました。以下がログイン情報です。"
      flash[:email] = @user.email
      flash[:password] = generated_password
      redirect_to admin_user_path(@user)
    else
      # Rails.logger.debug "ユーザー情報の取得に失敗しました: #{@user.errors.full_messages.join(', ')}"
      @companies = Company.all
      flash.now[:alert] = "ユーザーの作成に失敗しました。"
      render "new"
    end
  end

  def edit
  end

  def edit_myaccount
    @user = current_user
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "ユーザー情報が更新されました。"
    else
      flash.now[:alert] = "ユーザー情報の更新に失敗しました。"
      render :edit
    end
  end

  def update_myaccount
    @user = current_user

    # 現在のパスワード確認
    unless @user.authenticate(params[:current_password])

      flash.now[:alert] = "現在のパスワードが正しくありません"
      render :edit_myaccount and return
    end

    # 新しいパスワードと確認が一致しているか
    if params[:new_password] != params[:new_password_confirmation]
      flash.now[:alert] = "新しいパスワードが一致しません"
      render :edit_myaccount and return
    end

    # 更新処理
    if @user.update(password: params[:new_password], password_confirmation: params[:new_password_confirmation])
      redirect_to show_myaccount_admin_users_path, notice: "パスワードを更新しました"
    else
      flash.now[:alert] = "パスワードの更新に失敗しました"
      render :edit_myaccount
    end
  end

  def destroy
    if @user.admin? && User.where(admin: true).count <= 1
      flash[:alert] = "管理者ユーザーは削除できません"
      redirect_to admin_users_path
    else
      if @user.destroy
        flash[:notice] = "ユーザーが削除されました。"
      else
        flash[:alert] = "ユーザーの削除に失敗しました。"
      end
      redirect_to admin_users_path
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    if current_user == @user
      # 本人が編集する場合：パスワードも許可
      params.require(:user).permit(
        :name,
        :email,
        :phone_number,
      )
    else
      # 本人以外が編集する場合：パスワードは許可しない
      params.require(:user).permit(
        :name,
        :email,
        :phone_number,
      )
    end
  end


  def completed_signin(user)
    if user.admin?
      redirect_to admin_root_path
    else
      redirect_to root_path
    end
  end
end
