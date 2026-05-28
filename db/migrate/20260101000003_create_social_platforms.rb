class CreateSocialPlatforms < ActiveRecord::Migration[8.1]
  def change
    create_table :social_platforms, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string  :name,            null: false, limit: 60
      t.string  :slug,            null: false, limit: 40
      t.text    :base_url
      t.text    :icon_url
      t.boolean :supports_oauth,  null: false, default: false
      t.string  :api_version,     limit: 20
      t.boolean :is_active,       null: false, default: true
      t.datetime :created_at,     null: false, default: -> { "now()" }
    end

    add_index :social_platforms, :name, unique: true
    add_index :social_platforms, :slug, unique: true
  end
end
