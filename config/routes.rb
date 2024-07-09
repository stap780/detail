Rails.application.routes.draw do
  require 'sidekiq/web'

  mount Sidekiq::Web => '/sidekiq'

  resources :products do
    collection do
      get :edit_multiple
      put :update_multiple
      post :delete_selected
      post :bulk_export
      get :import
      get :csv_param
    end
  end
  resources :kares do
    member do
      get :pars_one
    end
    collection do
      get :pars
      get :import
      get :csv_param
      post :delete_selected
      post :bulk_export
    end
  end

  root to: 'visitors#index'
  devise_for :users
  resources :users

end
