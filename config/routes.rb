# frozen_string_literal: true

Rails.application.routes.draw do
  # ─── Devise Auth ──────────────────────────────────────────────────────────────
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions:      "users/sessions",
    confirmations: "users/confirmations"
  }

  # ─── Public Routes ────────────────────────────────────────────────────────────
  root to: "pages#home"
  get "blog",           to: "blogs#listing", as: :blog_archive
  get "blog/feed",      to: "blogs#feed",    as: :blog_feed, defaults: { format: :atom }
  get "sitemap.xml",    to: "sitemaps#show", defaults: { format: :xml }, as: :sitemap

  # Public blog posts live on the author's sub-host: <username>.<apex>/blog/<slug>
  # (declared after /blog and /blog/feed so those apex routes win on any host).
  # Match by host-suffix against the configured apex rather than ActionDispatch's
  # subdomain parsing, which depends on tld_length and fails for `*.localhost`.
  blog_host_constraint = lambda do |request|
    apex = Rails.application.routes.default_url_options[:host].to_s
    host = request.host.to_s
    apex.present? && host != apex && host.end_with?(".#{apex}")
  end
  constraints(blog_host_constraint) do
    get "blog/:slug", to: "blogs#show", as: :public_blog
    # Public author profile — the author is derived from the sub-host.
    get "about", to: "public_profiles#show", as: :public_profile
  end
  # `new` must be declared before the `:show` route below, otherwise `/topics/new`
  # is captured by `/topics/:id` (id="new"). Auth is enforced in TopicsController.
  get "topics/new",     to: "topics#new", as: :new_topic
  resources :topics,    only: [ :index, :show ]
  resources :templates, only: [ :index, :show ]

  # ─── Authenticated Web UI ─────────────────────────────────────────────────────
  authenticated :user do
    get "dashboard", to: "dashboard#index", as: :dashboard

    post "uploads", to: "uploads#create", as: :uploads

    resources :blogs, except: [ :show ] do
      resources :images, only: [ :create, :destroy ], controller: "blog_images" do
        delete :unused, on: :collection
      end
      member do
        patch :publish
        patch :archive
        patch :submit_review
        post  :schedule
      end
      collection do
        post :bulk_action
      end
    end

    resources :topics,    only: [ :create, :edit, :update, :destroy ]
    resources :templates, except: [ :index, :show ]

    resources :users, only: [ :index, :show, :update, :destroy ] do
      member do
        patch :toggle_active
        patch :change_role
      end
    end

    namespace :settings do
      resource :profile,  only: [ :show, :update ]
      resources :socials, only: [ :index, :create, :destroy ]
      resources :integrations do
        member { post :test_connection }
      end
      resources :webhooks do
        member do
          get  :delivery_log
          post :retry_event
        end
      end
    end
  end

  # ─── API v1 (JSON) ────────────────────────────────────────────────────────────
  namespace :api do
    namespace :v1 do
      # Auth
      post "auth/verify-email", to: "auth#verify_email"

      # Blogs
      resources :blogs do
        member do
          post :publish
          post :schedule
          post :submit_review
        end
      end

      # Topics
      resources :topics

      # Templates
      resources :templates, only: [ :index, :create ]

      # Images
      resources :images, only: [ :create, :destroy ]

      # Analytics
      scope "/analytics" do
        get  "/:blog_id", to: "analytics#show",  as: :analytics_show
        post "/sync",     to: "analytics#sync",  as: :analytics_sync
      end

      # Current user
      scope "/users" do
        get    "/me",          to: "users#show",           as: :me
        patch  "/me",          to: "users#update",         as: :update_me
        get    "/me/socials",  to: "user_socials#index",   as: :me_socials
        post   "/me/socials",  to: "user_socials#create",  as: :create_me_social
        delete "/me/socials/:id", to: "user_socials#destroy", as: :destroy_me_social
      end

      # Integrations (Owner only)
      resources :integrations do
        member { post :test }
      end

      # Webhooks (Owner only)
      resources :webhooks do
        member do
          post "retry/:event_id", to: "webhooks#retry_event", as: :retry_event
        end
      end
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
