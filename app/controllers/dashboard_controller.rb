# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # Admins/owners see site-wide data; regular users see only their own blogs.
    @site_wide = current_user.owner_role? || current_user.admin_role?
    blogs     = dashboard_blogs
    analytics = dashboard_analytics

    @total_blogs   = blogs.count
    @total_views   = analytics.sum(:views)
    @avg_seo_score = blogs.where.not(seo_score: nil).average(:seo_score)&.round(1) || 0
    @avg_promotion = blogs.where.not(promotion_score: nil).average(:promotion_score)&.round(1) || 0

    # Views over last 30 days for chart
    @views_by_day = analytics.last_30_days
                             .group(:recorded_date)
                             .sum(:views)

    # Top 5 blogs by views this week
    this_week_views = analytics.last_7_days
                               .group(:blog_id)
                               .sum(:views)
    top_blog_ids = this_week_views.sort_by { |_, v| -v }.first(5).map(&:first)

    @top_blogs = blogs.where(id: top_blog_ids)
                      .includes(:author, :topics)
                      .index_by(&:id)
                      .values_at(*top_blog_ids)
                      .compact

    # Previous week for trend indicator
    prev_week_views = analytics.where(recorded_date: 14.days.ago.to_date..7.days.ago.to_date)
                               .group(:blog_id)
                               .sum(:views)

    @trends = top_blog_ids.index_with do |blog_id|
      current  = this_week_views[blog_id].to_i
      previous = prev_week_views[blog_id].to_i
      previous.zero? ? :up : (current >= previous ? :up : :down)
    end

    @recent_blogs = blogs.recent.limit(5).includes(:author)
  end

  private

  # Blogs in scope for the current user's dashboard.
  def dashboard_blogs
    scope = Blog.not_deleted
    @site_wide ? scope : scope.where(author_id: current_user.id)
  end

  # Analytics rows in scope for the current user's dashboard.
  def dashboard_analytics
    @site_wide ? BlogAnalytic.all : BlogAnalytic.joins(:blog).where(blogs: { author_id: current_user.id })
  end
end
