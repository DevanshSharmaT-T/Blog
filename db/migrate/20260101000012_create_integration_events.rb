class CreateIntegrationEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :integration_events, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :integration, null: false, foreign_key: { to_table: :third_party_integrations }, type: :uuid
      t.references :blog, foreign_key: true, type: :uuid  # nullable

      t.string  :event_type,    null: false, limit: 80
      t.string  :direction,     null: false, limit: 10    # 'outbound' | 'inbound'
      t.jsonb   :payload
      t.integer :status_code,   limit: 2
      t.boolean :success,       null: false, default: true
      t.text    :error_message
      t.integer :duration_ms

      t.datetime :created_at, null: false, default: -> { "now()" }
    end

    add_index :integration_events, :event_type
    add_index :integration_events, :created_at
  end
end
