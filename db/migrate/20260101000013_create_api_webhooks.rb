class CreateApiWebhooks < ActiveRecord::Migration[8.1]
  def change
    create_table :api_webhooks, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :user,           null: false, foreign_key: true, type: :uuid
      t.string  :name,              null: false, limit: 120
      t.text    :target_url,        null: false
      t.text    :secret_ciphertext, null: false  # encrypted HMAC secret
      t.text    :events,            array: true, default: [], null: false
      t.boolean :is_active,         null: false, default: true
      t.datetime :last_triggered_at
      t.integer :failure_count,     null: false, default: 0, limit: 2

      t.timestamps null: false
    end

    add_index :api_webhooks, :is_active
  end
end
