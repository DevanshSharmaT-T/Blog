# frozen_string_literal: true

module Api
  module V1
    class AnalyticsController < BaseController
      # GET /api/v1/analytics/:blog_id?days=30
      def show
        blog = Blog.find(params[:blog_id])
        authorize! :read, BlogAnalytic

        days = [ (params[:days] || 30).to_i, 365 ].min
        analytics = blog.blog_analytics
                        .where(recorded_date: days.days.ago.to_date..)
                        .by_date

        render json: {
          blog_id:    blog.id,
          title:      blog.title,
          days:       days,
          analytics:  analytics.map { |a| analytic_json(a) },
          totals: {
            views:           analytics.sum(&:views),
            unique_visitors: analytics.sum(&:unique_visitors),
            social_shares:   analytics.sum(&:social_shares),
            backlinks:       analytics.maximum(:backlinks) || 0
          },
          scores: {
            seo_score:         blog.seo_score,
            readability_score: blog.readability_score,
            promotion_score:   blog.promotion_score
          }
        }
      end

      # POST /api/v1/analytics/sync
      def sync
        authorize! :manage, BlogAnalytic

        # Placeholder: real implementation would call connected analytics integration
        # For each active analytics integration, pull data and upsert blog_analytics rows
        integrations = ThirdPartyIntegration.active.by_type("analytics").for_user(current_user)

        results = integrations.map do |integration|
          { provider: integration.provider, status: "sync_queued" }
        end

        WebhookDispatchJob.perform_later("analytics.synced", { user_id: current_user.id })

        render json: { message: "Sync initiated.", integrations: results }
      end

      private

      def analytic_json(a)
        {
          date:                 a.recorded_date.iso8601,
          views:                a.views,
          unique_visitors:      a.unique_visitors,
          avg_time_on_page_secs: a.avg_time_on_page_secs,
          bounce_rate:          a.bounce_rate,
          backlinks:            a.backlinks,
          social_shares:        a.social_shares,
          referrer_breakdown:   a.referrer_breakdown,
          source:               a.source
        }
      end
    end
  end
end
