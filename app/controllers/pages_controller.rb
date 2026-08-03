# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate_user!

  def home
    @featured_blogs  = Blog.visible.featured.includes(:author, :topics).limit(3)
    @recent_blogs    = Blog.visible.recent.includes(:author, :topics).limit(6)
    @developer_blogs = Blog.visible.recent
                           .joins(:author).where(users: { role: %w[owner admin] })
                           .includes(:author, :topics).limit(3)
    @topics          = Topic.active.order(post_count: :desc).limit(10)
  end
end
