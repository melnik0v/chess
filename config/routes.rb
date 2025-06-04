Rails.application.routes.draw do
  # Defines the root path route ("/")
  root "home#index"

  # Catch-all route for the frontend (unless it starts with /api)
  get '*path', to: 'home#index', constraints: ->(req) { !req.path.starts_with?('/api') && req.format.html? }

  namespace :api do
    namespace :v1 do
      resources :games, only: [:create, :show, :update], param: :uuid do
        post :join, on: :member
      end
    end
  end
end
