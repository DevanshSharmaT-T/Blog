class EnablePgcryptoAndEnums < ActiveRecord::Migration[8.1]
  def up
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    execute <<~SQL
      CREATE TYPE user_role AS ENUM ('owner', 'admin', 'user', 'visitor');
      CREATE TYPE blog_status AS ENUM ('draft', 'review', 'scheduled', 'published', 'archived');
      CREATE TYPE integration_type AS ENUM ('analytics', 'email', 'social', 'ai', 'storage', 'seo', 'cms', 'payment', 'notification', 'custom');
      CREATE TYPE integration_status AS ENUM ('active', 'inactive', 'error', 'revoked');
    SQL
  end

  def down
    execute <<~SQL
      DROP TYPE IF EXISTS user_role;
      DROP TYPE IF EXISTS blog_status;
      DROP TYPE IF EXISTS integration_type;
      DROP TYPE IF EXISTS integration_status;
    SQL

    disable_extension "pgcrypto"
  end
end
