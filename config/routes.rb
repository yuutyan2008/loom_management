Rails.application.routes.draw do
  # Deviseのルーティング（後ステップで設定）
  # devise_for :users, controllers: {
  #   sessions: 'users/sessions',
  #   registrations: 'devise/registrations'
  # }

  # 管理者用の名前空間
  namespace :admin do
    root to: 'home#index' # 管理者のホームページ
    resources :tasks
    resources :machines
    resources :orders
    resources :users
    resources :products
  end

  # 通常ユーザー用の名前空間
  namespace :user do
    get 'home/index'
    root to: 'home#index'
    resources :users, only: [:show, :edit, :update]
    resources :machines, only: [:index, :show, :new, :create, :edit, :update, :destroy]
    resources :orders, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  end
end
