# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
  
  # Diagnostic endpoints (no auth required - for debugging only)
  get "diagnostic" => "diagnostic#show"
  get "diagnostic/user" => "diagnostic#user"
  post "diagnostic/make_admin" => "diagnostic#make_admin"

  # Sidekiq Web UI (protected in production)
  mount Sidekiq::Web => "/sidekiq"

  # Webhooks (no authentication required, verified by signature)
  namespace :webhooks do
    post "linear", to: "linear#receive"
  end

  # GraphQL API (public)
  post "/graphql", to: "graphql#execute"

  # GraphiQL in development
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end

  # REST API (internal) - Single tenant, no workspace scoping
  namespace :api do
    namespace :v1 do
      # Authentication (Magic Link)
      namespace :auth do
        post "magic-link", to: "sessions#send_magic_link"
        post "verify-magic-link", to: "sessions#verify_magic_link"
        post "token-login", to: "sessions#token_login"
        delete "logout", to: "sessions#logout"
        get "me", to: "sessions#me"
      end

      # Users (admin only)
      resources :users, only: %i[index show update destroy] do
        member do
          patch :role
        end
      end

      # Teams
      resources :teams, param: :key, only: %i[index create show update destroy] do
        resources :members, controller: "team_members", only: %i[index create destroy], param: :user_id
        resources :workflow_states, only: %i[index]
        resources :cycles, only: %i[index]
      end

      # Projects
      resources :projects, param: :slug, only: %i[index create show update destroy] do
        resources :members, controller: "project_members", only: %i[index create destroy], param: :user_id
      end

      # Project Updates (status reports / pulse feed)
      resources :project_updates, only: %i[index show]

      # Labels (global and team-specific)
      resources :labels, only: %i[index create show update destroy]

      # Issues
      resources :issues, only: %i[index create show update destroy] do
        resources :comments, only: %i[index create update destroy]
        collection do
          post :bulk
        end
      end

      # Comments (standalone for updates)
      resources :comments, only: %i[update destroy] do
        resources :reactions, only: %i[create destroy]
      end

      # Saved Views
      resources :views, only: %i[index create show update destroy]

      # Notifications
      resources :notifications, only: %i[index] do
        member do
          patch :read
        end
        collection do
          post :read_all
        end
      end

      # Search
      get "search", to: "search#index"

      # Slack Emojis (custom workspace emojis)
      resources :emojis, only: %i[index]

      # Settings (admin only)
      namespace :settings do
        get "/", to: "settings#show"
        patch "/", to: "settings#update"
      end
    end
  end
end
