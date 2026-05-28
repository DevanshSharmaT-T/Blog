class CreateBlogTopics < ActiveRecord::Migration[8.1]
  def change
    create_table :blog_topics, id: false do |t|
      t.references :blog,  null: false, foreign_key: true, type: :uuid
      t.references :topic, null: false, foreign_key: true, type: :uuid
      t.datetime :assigned_at, null: false, default: -> { "now()" }
    end

    add_index :blog_topics, [ :blog_id, :topic_id ], unique: true, name: "blog_topics_pkey"
    execute "ALTER TABLE blog_topics ADD PRIMARY KEY (blog_id, topic_id);"
  end
end
