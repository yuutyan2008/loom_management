Rails.application.routes.draw do
  # ログイン機能のルーティング
  get 'login', to: 'sessions#new', as: 'login'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy', as: 'logout'
  get 'signin', to: 'users#new'
  post 'signin', to: 'users#create'

  # 管理者用の名前空間
  namespace :admin do
    root to: 'home#index'
    resources :machines
    resources :orders
    resources :users
    resources :products

    resources :process_estimates, only: [:index, :new, :create] do
      collection do
        get :edit_all
        patch :update_all
      end
    end
  end

  # 通常ユーザー用のリソース
  resources :machines, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  resources :orders, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  resources :users, only: [:new, :create, :show, :edit, :update]
  root to: 'home#index'
end
