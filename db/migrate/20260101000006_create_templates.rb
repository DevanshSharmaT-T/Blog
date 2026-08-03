class CreateTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :templates, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string  :name,          null: false, limit: 120
      t.string  :slug,          null: false, limit: 80
      t.text    :description
      t.text    :thumbnail_url
      t.text    :preview_url
      t.jsonb   :layout_config, null: false, default: {}
      t.string  :category,      limit: 50
      t.boolean :is_premium,    null: false, default: false
      t.boolean :is_active,     null: false, default: true
      t.references :created_by, foreign_key: { to_table: :users }, type: :uuid
      t.integer :usage_count,   null: false, default: 0

      t.timestamps null: false
    end

    add_index :templates, :slug, unique: true
    add_index :templates, :layout_config, using: :gin
  end
end
