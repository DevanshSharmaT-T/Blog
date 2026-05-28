class CreateBlogs < ActiveRecord::Migration[8.1]
  def change
    create_table :blogs, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :author,   null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :template, foreign_key: true, type: :uuid

      t.string  :title,              null: false, limit: 255
      t.string  :slug,               null: false, limit: 255
      t.text    :excerpt
      t.text    :content,            null: false, default: ""
      t.string  :content_format,     null: false, default: "markdown", limit: 20
      t.text    :cover_image_url
      t.column  :status, :blog_status, null: false, default: "draft"

      # SEO
      t.string  :seo_title,          limit: 70
      t.string  :seo_description,    limit: 160
      t.integer :seo_score,          limit: 2
      t.integer :readability_score,  limit: 2
      t.integer :promotion_score,    limit: 2

      # Metadata
      t.integer :word_count
      t.integer :reading_time_mins,  limit: 2
      t.boolean :featured,           null: false, default: false
      t.boolean :allow_comments,     null: false, default: true

      # Timestamps
      t.datetime :published_at
      t.datetime :scheduled_at
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :blogs, :slug,         unique: true
    add_index :blogs, :status
    add_index :blogs, :published_at
    add_index :blogs, :deleted_at
    add_index :blogs, :featured
    add_index :blogs, :scheduled_at
  end
end
