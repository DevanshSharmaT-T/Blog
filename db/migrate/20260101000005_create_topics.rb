class CreateTopics < ActiveRecord::Migration[8.1]
  def change
    create_table :topics, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string  :name,        null: false, limit: 80
      t.string  :slug,        null: false, limit: 80
      t.text    :description
      t.string  :color_hex,   limit: 7
      t.string  :icon_name,   limit: 50
      t.references :parent,   foreign_key: { to_table: :topics }, type: :uuid
      t.integer :post_count,  null: false, default: 0
      t.boolean :is_active,   null: false, default: true
      t.datetime :created_at, null: false, default: -> { "now()" }
    end

    add_index :topics, :slug, unique: true
  end
end
