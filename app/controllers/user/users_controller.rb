class User::UsersController < ApplicationController
  def show
    # デモ用に最初のユーザーを取得
    @user = User.first
  end

  def edit
    @user = User.first
  end

  def update
    @user = User.first
    if @user.update(user_params)
      redirect_to user_user_path(@user), notice: 'ユーザー情報が更新されました。'
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :phone_number)
  end
end
