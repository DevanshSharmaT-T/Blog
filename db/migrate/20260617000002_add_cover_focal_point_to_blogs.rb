class AddCoverFocalPointToBlogs < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :cover_focal_x, :decimal, precision: 5, scale: 2, default: 50.0, null: false
    add_column :blogs, :cover_focal_y, :decimal, precision: 5, scale: 2, default: 50.0, null: false
  end
end
