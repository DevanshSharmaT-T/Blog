class ScopeBlogSlugToAuthor < ActiveRecord::Migration[8.1]
  def up
    remove_index :blogs, name: "index_blogs_on_slug" if index_exists?(:blogs, :slug, name: "index_blogs_on_slug")
    add_index :blogs, [ :author_id, :slug ], unique: true, name: "index_blogs_on_author_id_and_slug"
  end

  def down
    remove_index :blogs, name: "index_blogs_on_author_id_and_slug" if index_exists?(:blogs, [ :author_id, :slug ], name: "index_blogs_on_author_id_and_slug")
    add_index :blogs, :slug, unique: true, name: "index_blogs_on_slug"
  end
end
