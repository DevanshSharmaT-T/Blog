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

  # Interactive field validation (banned words / disposable email). Public so the
  # signup form can call it before the visitor is authenticated.
  post "moderation/check", to: "moderation_checks#create", as: :moderation_check
  get "blog",           to: "blogs#listing", as: :blog_archive
  get "blog/feed",      to: "blogs#feed",    as: :blog_feed, defaults: { format: :atom }
  get "sitemap.xml",    to: "sitemaps#show", defaults: { format: :xml }, as: :sitemap

  # Public blog posts & author profiles live under the author's handle.
  #
  # ── PATH-BASED MODE (active) ──────────────────────────────────────────────────
  # /@<username>/blog/<slug> and /@<username>. Served on a single host (works on the
  # free *.onrender.com domain — no wildcard TLS/DNS needed). The author comes from
  # the :username path segment (see BlogsController#set_blog & PublicProfilesController).
  # The `@` prefix guarantees these never collide with other top-level routes.
  get "@:username/blog/:slug", to: "blogs#show",           as: :public_blog,    constraints: { username: /[a-z0-9][a-z0-9-]*/ }
  get "@:username",            to: "public_profiles#show", as: :public_profile, constraints: { username: /[a-z0-9][a-z0-9-]*/ }
  #
  # ── SUBDOMAIN MODE (disabled) ─────────────────────────────────────────────────
  # Per-author sub-hosts: <username>.<apex>/blog/<slug> and <username>.<apex>/about.
  # Requires a wildcard custom domain (*.yourdomain.com) with wildcard TLS — NOT
  # possible on a free *.onrender.com host. To re-enable: uncomment this block, remove
  # the two path-based routes above, and revert the matching builders/controllers
  # (grep "SUBDOMAIN MODE"). Matches by host-suffix against the configured apex (not
  # tld_length-based subdomain parsing, which fails for `*.localhost`).
  # blog_host_constraint = lambda do |request|
  #   apex = Rails.application.routes.default_url_options[:host].to_s
  #   host = request.host.to_s
  #   apex.present? && host != apex && host.end_with?(".#{apex}")
  # end
  # constraints(blog_host_constraint) do
  #   get "blog/:slug", to: "blogs#show", as: :public_blog
  #   get "about", to: "public_profiles#show", as: :public_profile
  # end
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
        patch :approve_moderation
        patch :reject_moderation
      end
      collection do
        post :bulk_action
        get  :moderation_queue
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
