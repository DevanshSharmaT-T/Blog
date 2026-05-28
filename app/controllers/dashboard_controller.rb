# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :require_dashboard_access!

  def index
    @total_blogs   = Blog.not_deleted.count
    @total_views   = BlogAnalytic.sum(:views)
    @avg_seo_score = Blog.not_deleted.where.not(seo_score: nil).average(:seo_score)&.round(1) || 0
    @avg_promotion = Blog.not_deleted.where.not(promotion_score: nil).average(:promotion_score)&.round(1) || 0

    # Views over last 30 days for chart
    @views_by_day = BlogAnalytic.last_30_days
                                .group(:recorded_date)
                                .sum(:views)

    # Top 5 blogs by views this week
    this_week_views = BlogAnalytic.last_7_days
                                  .group(:blog_id)
                                  .sum(:views)
    top_blog_ids = this_week_views.sort_by { |_, v| -v }.first(5).map(&:first)

    @top_blogs = Blog.not_deleted
                     .where(id: top_blog_ids)
                     .includes(:author, :topics)
                     .index_by(&:id)
                     .values_at(*top_blog_ids)
                     .compact

    # Previous week for trend indicator
    prev_week_views = BlogAnalytic.where(recorded_date: 14.days.ago.to_date..7.days.ago.to_date)
                                  .group(:blog_id)
                                  .sum(:views)

    @trends = top_blog_ids.index_with do |blog_id|
      current  = this_week_views[blog_id].to_i
      previous = prev_week_views[blog_id].to_i
      previous.zero? ? :up : (current >= previous ? :up : :down)
    end

    @recent_blogs = Blog.not_deleted.recent.limit(5).includes(:author)
  end

  private

  def require_dashboard_access!
    unless current_user.owner_role? || current_user.admin_role?
      flash[:alert] = "Dashboard access is restricted to Owner and Admin roles."
      redirect_to root_path
    end
  end
end
