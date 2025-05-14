Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Redirect root to API documentation
  root to: redirect("/api-docs")

  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      get "ping", to: "ping#index"
      resources :users, param: :user_id do
        resources :transactions, only: [ :create ]
        member do
          get "points"
          get "rewards"
        end
      end
    end
  end

  # Mount Swagger UI and API documentation
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
end
