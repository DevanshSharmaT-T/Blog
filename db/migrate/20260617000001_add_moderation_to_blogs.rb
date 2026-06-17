class AddModerationToBlogs < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :moderation_state, :string, null: false, default: "clean"
    add_column :blogs, :moderation_flagged_terms, :text
    add_column :blogs, :moderation_note, :text
    add_column :blogs, :moderated_at, :datetime
    add_reference :blogs, :moderated_by, type: :uuid, null: true,
                  foreign_key: { to_table: :users }, index: true

    add_index :blogs, :moderation_state
  end
end
