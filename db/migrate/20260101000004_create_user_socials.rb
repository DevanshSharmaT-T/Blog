class CreateUserSocials < ActiveRecord::Migration[8.1]
  def change
    create_table :user_socials, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :user,            null: false, foreign_key: true, type: :uuid
      t.references :social_platform, null: false, foreign_key: true, type: :uuid
      t.string  :handle,             null: false, limit: 100
      t.text    :profile_url
      t.integer :follower_count
      t.boolean :is_verified,        null: false, default: false
      t.boolean :is_public,          null: false, default: true

      # Encrypted OAuth tokens (stored as encrypted strings)
      t.text    :access_token_ciphertext
      t.text    :refresh_token_ciphertext
      t.datetime :token_expires_at
      t.datetime :last_synced_at

      t.timestamps null: false
    end

    add_index :user_socials, [ :user_id, :social_platform_id ], unique: true
  end
end
