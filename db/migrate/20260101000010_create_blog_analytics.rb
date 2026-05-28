class CreateBlogAnalytics < ActiveRecord::Migration[8.1]
  def change
    create_table :blog_analytics, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :blog,              null: false, foreign_key: true, type: :uuid
      t.date       :recorded_date,     null: false
      t.integer    :views,             null: false, default: 0
      t.integer    :unique_visitors,   null: false, default: 0
      t.integer    :avg_time_on_page_secs
      t.decimal    :bounce_rate,       precision: 5, scale: 2
      t.integer    :backlinks,         null: false, default: 0
      t.decimal    :search_rank_score, precision: 5, scale: 2
      t.decimal    :promotion_ease_score, precision: 5, scale: 2
      t.integer    :social_shares,     null: false, default: 0
      t.jsonb      :referrer_breakdown
      t.string     :source,            null: false, default: "internal", limit: 50

      t.datetime   :created_at, null: false, default: -> { "now()" }
    end

    add_index :blog_analytics, [ :blog_id, :recorded_date ], unique: true
    add_index :blog_analytics, :recorded_date
    add_index :blog_analytics, :referrer_breakdown, using: :gin
  end
end
