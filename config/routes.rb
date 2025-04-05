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
    # Companyのshowアクションへのリソースフルなルートを追加
    resources :companies, only: [:show], controller: 'home'

    resources :machines
    resources :orders do
      collection do
        get 'past_orders'
      end
      collection do
        get 'gant_index'
      end
      collection do
        get 'ma_select_company'
      end
      collection do
        get 'ma_index'
      end
    end
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
  resources :orders do
    collection do
      get 'past_orders'
    end
  end
  root to: 'home#index'
  # HomeControllerのupdateアクションを定義
  patch 'home/update', to: 'home#update', as: 'update_home'
end
