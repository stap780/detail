Rails.application.routes.draw do
  require 'sidekiq/web'
  require 'sidekiq-scheduler/web'

  mount Sidekiq::Web => '/sidekiq'

  resources :idcs do
    member do
      get :pars_one
    end
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
      get :csv_param
      post :delete_selected
      post :bulk_export
    end
  end

  root to: 'visitors#index'
  devise_for :users
  resources :users

end
