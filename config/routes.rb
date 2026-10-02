Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "homestead#show"
  resource :homestead, only: :update, controller: "homestead"
  post "plots/plant", to: "plots#plant_next", as: :plant_next_plot
  post "plots/buy", to: "plots#buy", as: :buy_plot
  post "plots/:id/plant", to: "plots#plant", as: :plant_plot
  post "plots/:id/harvest", to: "plots#harvest", as: :harvest_plot
  post "plots/:id/clear", to: "plots#clear", as: :clear_plot
end
