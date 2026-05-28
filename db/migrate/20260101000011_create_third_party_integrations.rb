class CreateThirdPartyIntegrations < ActiveRecord::Migration[8.1]
  def change
    create_table :third_party_integrations, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :user, foreign_key: true, type: :uuid  # nullable for system-level
      t.string  :provider,       null: false, limit: 60
      t.column  :provider_type, :integration_type, null: false
      t.string  :label,          limit: 120
      t.jsonb   :config,         null: false, default: {}
      t.text    :credentials_ciphertext  # encrypted JSON credentials
      t.column  :status, :integration_status, null: false, default: "inactive"
      t.datetime :last_tested_at
      t.text    :error_message
      t.jsonb   :metadata

      t.timestamps null: false
    end

    add_index :third_party_integrations, :provider
    add_index :third_party_integrations, :status
    add_index :third_party_integrations, :config, using: :gin
  end
end
