class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid, default: "gen_random_uuid()" do |t|
      # Devise columns
      t.string :email,              null: false, limit: 255
      t.string :encrypted_password, null: false, default: ""

      # Devise recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      # Devise rememberable
      t.datetime :remember_created_at

      # Devise confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email

      # Profile
      t.string :name,        null: false, limit: 120
      t.column :role, :user_role, null: false, default: "user"
      t.text   :avatar_url
      t.text   :bio
      t.text   :website_url

      # Status
      t.boolean  :is_active,          null: false, default: true
      t.datetime :email_verified_at
      t.datetime :last_login_at
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    add_index :users, :role
    add_index :users, :deleted_at
  end
end
