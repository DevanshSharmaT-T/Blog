class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  RESERVED = %w[www app api admin blog assets mail root support help settings dashboard].freeze

  # Lightweight model to avoid the real User validations/callbacks during backfill.
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    add_column :users, :username, :string, limit: 50 unless column_exists?(:users, :username)

    say_with_time "Backfilling usernames" do
      taken = []
      MigrationUser.reset_column_information
      MigrationUser.where(username: nil).find_each do |u|
        base = u.name.to_s.parameterize
        base = u.email.to_s.split("@").first.to_s.parameterize if base.blank?
        base = "user" if base.blank?
        base = base[0, 40]
        base = "#{base}-u" if RESERVED.include?(base)
        candidate = base
        i = 1
        while taken.include?(candidate) || MigrationUser.where(username: candidate).exists?
          i += 1
          candidate = "#{base}-#{i}"
        end
        taken << candidate
        u.update_columns(username: candidate)
      end
    end

    change_column_null :users, :username, false
    add_index :users, :username, unique: true
  end

  def down
    remove_index :users, :username if index_exists?(:users, :username)
    remove_column :users, :username
  end
end
