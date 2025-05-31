Rails.application.routes.draw do
  # Defines the root path route ("/")
  root "home#index"

  # Catch-all route for the frontend (unless it starts with /api)
  get '*path', to: 'home#index', constraints: ->(req) { !req.path.starts_with?('/api') && req.format.html? }

  namespace :api do
    namespace :v1 do
      get "protected/index"
      resources :users, only: [:create] # Регистрация
      resources :sessions, only: [:create] # Вход
      get '/me', to: 'users#show'

      # Маршруты для Passkeys
      get '/passkeys/registration_options', to: 'passkeys#registration_options'
      post '/passkeys/registration_verification', to: 'passkeys#registration_verification'
      get '/passkeys/authentication_options', to: 'passkeys#authentication_options'
      post '/passkeys/authentication_verification', to: 'passkeys#authentication_verification'

      resources :games, only: [:create, :show, :update] do
        post :join, on: :collection
      end
    end
  end
end
