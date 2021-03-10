Rails.application.routes.draw do

  resources :products do
    collection do
      get :edit_multiple
      put :update_multiple
      post :delete_selected
      get :import
      get :csv_param
    end
  end
  resources :kares do
    collection do
      get :import
      get :csv_param
    end
  end

  root to: 'visitors#index'
  devise_for :users
  resources :users
end
