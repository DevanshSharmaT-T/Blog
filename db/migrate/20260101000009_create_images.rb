class CreateImages < ActiveRecord::Migration[8.1]
  def change
    create_table :images, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :blog,        null: false, foreign_key: true, type: :uuid
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }, type: :uuid

      t.text    :url,            null: false
      t.text    :storage_key
      t.string  :mime_type,      limit: 50
      t.integer :file_size_bytes
      t.integer :width_px
      t.integer :height_px
      t.text    :alt_text
      t.text    :caption
      t.integer :display_order, null: false, default: 0, limit: 2

      t.datetime :created_at, null: false, default: -> { "now()" }
    end

  end
end
