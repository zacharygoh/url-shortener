Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  root "short_urls#index"

  # API endpoints
  namespace :api do
    # URL Shortener endpoints
    post "shorten", to: "short_urls#create"
    get "stats/:short_code", to: "short_urls#stats"
    get "report", to: "short_urls#report"

    # Extension 1: DEX Data Queries (Uniswap V3 via The Graph)
    scope path: "dex" do
      get "pools", to: "dex_queries#index"
      get "pools/:id", to: "dex_queries#show"
    end
  end

  # Must be last - catch-all for short code redirects
  get "/:short_code", to: "redirects#show", constraints: { short_code: /[a-zA-Z0-9]+/ }
end
