# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_29_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "blog_status", ["draft", "review", "scheduled", "published", "archived"]
  create_enum "integration_status", ["active", "inactive", "error", "revoked"]
  create_enum "integration_type", ["analytics", "email", "social", "ai", "storage", "seo", "cms", "payment", "notification", "custom"]
  create_enum "user_role", ["owner", "admin", "user", "visitor"]

  create_table "api_webhooks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "events", default: [], null: false, array: true
    t.integer "failure_count", limit: 2, default: 0, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "last_triggered_at"
    t.string "name", limit: 120, null: false
    t.text "secret_ciphertext", null: false
    t.text "target_url", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["is_active"], name: "index_api_webhooks_on_is_active"
    t.index ["user_id"], name: "index_api_webhooks_on_user_id"
  end

  create_table "blog_analytics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "avg_time_on_page_secs"
    t.integer "backlinks", default: 0, null: false
    t.uuid "blog_id", null: false
    t.decimal "bounce_rate", precision: 5, scale: 2
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.decimal "promotion_ease_score", precision: 5, scale: 2
    t.date "recorded_date", null: false
    t.jsonb "referrer_breakdown"
    t.decimal "search_rank_score", precision: 5, scale: 2
    t.integer "social_shares", default: 0, null: false
    t.string "source", limit: 50, default: "internal", null: false
    t.integer "unique_visitors", default: 0, null: false
    t.integer "views", default: 0, null: false
    t.index ["blog_id", "recorded_date"], name: "index_blog_analytics_on_blog_id_and_recorded_date", unique: true
    t.index ["blog_id"], name: "index_blog_analytics_on_blog_id"
    t.index ["recorded_date"], name: "index_blog_analytics_on_recorded_date"
    t.index ["referrer_breakdown"], name: "index_blog_analytics_on_referrer_breakdown", using: :gin
  end

  create_table "blog_topics", primary_key: ["blog_id", "topic_id"], force: :cascade do |t|
    t.datetime "assigned_at", default: -> { "now()" }, null: false
    t.uuid "blog_id", null: false
    t.uuid "topic_id", null: false
    t.index ["blog_id", "topic_id"], name: "blog_topics_pkey", unique: true
    t.index ["blog_id"], name: "index_blog_topics_on_blog_id"
    t.index ["topic_id"], name: "index_blog_topics_on_topic_id"
  end

  create_table "blogs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "allow_comments", default: true, null: false
    t.uuid "author_id", null: false
    t.text "content", default: "", null: false
    t.string "content_format", limit: 20, default: "markdown", null: false
    t.text "cover_image_url"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "excerpt"
    t.boolean "featured", default: false, null: false
    t.integer "promotion_score", limit: 2
    t.datetime "published_at"
    t.integer "readability_score", limit: 2
    t.integer "reading_time_mins", limit: 2
    t.datetime "scheduled_at"
    t.string "seo_description", limit: 160
    t.integer "seo_score", limit: 2
    t.string "seo_title", limit: 70
    t.string "slug", limit: 255, null: false
    t.enum "status", default: "draft", null: false, enum_type: "blog_status"
    t.uuid "template_id"
    t.string "title", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.integer "word_count"
    t.index ["author_id", "slug"], name: "index_blogs_on_author_id_and_slug", unique: true
    t.index ["author_id"], name: "index_blogs_on_author_id"
    t.index ["deleted_at"], name: "index_blogs_on_deleted_at"
    t.index ["featured"], name: "index_blogs_on_featured"
    t.index ["published_at"], name: "index_blogs_on_published_at"
    t.index ["scheduled_at"], name: "index_blogs_on_scheduled_at"
    t.index ["status"], name: "index_blogs_on_status"
    t.index ["template_id"], name: "index_blogs_on_template_id"
  end

  create_table "images", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "alt_text"
    t.uuid "blog_id", null: false
    t.text "caption"
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.integer "display_order", limit: 2, default: 0, null: false
    t.integer "file_size_bytes"
    t.integer "height_px"
    t.string "mime_type", limit: 50
    t.text "storage_key"
    t.uuid "uploaded_by_id", null: false
    t.text "url", null: false
    t.integer "width_px"
    t.index ["blog_id"], name: "index_images_on_blog_id"
    t.index ["uploaded_by_id"], name: "index_images_on_uploaded_by_id"
  end

  create_table "integration_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blog_id"
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.string "direction", limit: 10, null: false
    t.integer "duration_ms"
    t.text "error_message"
    t.string "event_type", limit: 80, null: false
    t.uuid "integration_id", null: false
    t.jsonb "payload"
    t.integer "status_code", limit: 2
    t.boolean "success", default: true, null: false
    t.index ["blog_id"], name: "index_integration_events_on_blog_id"
    t.index ["created_at"], name: "index_integration_events_on_created_at"
    t.index ["event_type"], name: "index_integration_events_on_event_type"
    t.index ["integration_id"], name: "index_integration_events_on_integration_id"
  end

  create_table "social_platforms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "api_version", limit: 20
    t.text "base_url"
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.text "icon_url"
    t.boolean "is_active", default: true, null: false
    t.string "name", limit: 60, null: false
    t.string "slug", limit: 40, null: false
    t.boolean "supports_oauth", default: false, null: false
    t.index ["name"], name: "index_social_platforms_on_name", unique: true
    t.index ["slug"], name: "index_social_platforms_on_slug", unique: true
  end

  create_table "templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "category", limit: 50
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.boolean "is_premium", default: false, null: false
    t.jsonb "layout_config", default: {}, null: false
    t.string "name", limit: 120, null: false
    t.text "preview_url"
    t.string "slug", limit: 80, null: false
    t.text "thumbnail_url"
    t.datetime "updated_at", null: false
    t.integer "usage_count", default: 0, null: false
    t.index ["created_by_id"], name: "index_templates_on_created_by_id"
    t.index ["layout_config"], name: "index_templates_on_layout_config", using: :gin
    t.index ["slug"], name: "index_templates_on_slug", unique: true
  end

  create_table "third_party_integrations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "credentials_ciphertext"
    t.text "error_message"
    t.string "label", limit: 120
    t.datetime "last_tested_at"
    t.jsonb "metadata"
    t.string "provider", limit: 60, null: false
    t.enum "provider_type", null: false, enum_type: "integration_type"
    t.enum "status", default: "inactive", null: false, enum_type: "integration_status"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["config"], name: "index_third_party_integrations_on_config", using: :gin
    t.index ["provider"], name: "index_third_party_integrations_on_provider"
    t.index ["status"], name: "index_third_party_integrations_on_status"
    t.index ["user_id"], name: "index_third_party_integrations_on_user_id"
  end

  create_table "topics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "color_hex", limit: 7
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.text "description"
    t.string "icon_name", limit: 50
    t.boolean "is_active", default: true, null: false
    t.string "name", limit: 80, null: false
    t.uuid "parent_id"
    t.integer "post_count", default: 0, null: false
    t.string "slug", limit: 80, null: false
    t.index ["parent_id"], name: "index_topics_on_parent_id"
    t.index ["slug"], name: "index_topics_on_slug", unique: true
  end

  create_table "user_socials", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "access_token_ciphertext"
    t.datetime "created_at", null: false
    t.integer "follower_count"
    t.string "handle", limit: 100, null: false
    t.boolean "is_public", default: true, null: false
    t.boolean "is_verified", default: false, null: false
    t.datetime "last_synced_at"
    t.text "profile_url"
    t.text "refresh_token_ciphertext"
    t.uuid "social_platform_id", null: false
    t.datetime "token_expires_at"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["social_platform_id"], name: "index_user_socials_on_social_platform_id"
    t.index ["user_id", "social_platform_id"], name: "index_user_socials_on_user_id_and_social_platform_id", unique: true
    t.index ["user_id"], name: "index_user_socials_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "avatar_url"
    t.text "bio"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email", limit: 255, null: false
    t.datetime "email_verified_at"
    t.string "encrypted_password", default: "", null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "last_login_at"
    t.string "name", limit: 120, null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.enum "role", default: "user", null: false, enum_type: "user_role"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.string "username", limit: 50, null: false
    t.text "website_url"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "api_webhooks", "users"
  add_foreign_key "blog_analytics", "blogs"
  add_foreign_key "blog_topics", "blogs"
  add_foreign_key "blog_topics", "topics"
  add_foreign_key "blogs", "templates"
  add_foreign_key "blogs", "users", column: "author_id"
  add_foreign_key "images", "blogs"
  add_foreign_key "images", "users", column: "uploaded_by_id"
  add_foreign_key "integration_events", "blogs"
  add_foreign_key "integration_events", "third_party_integrations", column: "integration_id"
  add_foreign_key "templates", "users", column: "created_by_id"
  add_foreign_key "third_party_integrations", "users"
  add_foreign_key "topics", "topics", column: "parent_id"
  add_foreign_key "user_socials", "social_platforms"
  add_foreign_key "user_socials", "users"
end
