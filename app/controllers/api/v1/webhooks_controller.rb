# frozen_string_literal: true

module Api
  module V1
    class WebhooksController < BaseController
      before_action :require_owner!
      before_action :set_webhook, only: [ :show, :update, :destroy, :retry_event ]

      def index
        webhooks = current_user.api_webhooks.order(created_at: :desc)
        render json: { webhooks: webhooks.map { |w| webhook_json(w) } }
      end

      def create
        webhook = current_user.api_webhooks.build(webhook_params)
        webhook.secret = SecureRandom.hex(32)

        if webhook.save
          render json: { webhook: webhook_json(webhook) }, status: :created
        else
          render json: { errors: webhook.errors.as_json }, status: :unprocessable_entity
        end
      end

      def update
        if @webhook.update(webhook_params)
          render json: { webhook: webhook_json(@webhook) }
        else
          render json: { errors: @webhook.errors.as_json }, status: :unprocessable_entity
        end
      end

      def destroy
        @webhook.destroy!
        render json: { message: "Webhook deleted." }
      end

      def retry_event
        event = IntegrationEvent.find(params[:event_id])
        WebhookDispatchJob.perform_later(event.event_type, event.payload&.dig("body") || {})
        render json: { message: "Event queued for retry." }
      end

      private

      def set_webhook
        @webhook = current_user.api_webhooks.find(params[:id])
      end

      def webhook_params
        params.require(:api_webhook).permit(:name, :target_url, :is_active, events: [])
      end

      def webhook_json(w)
        {
          id: w.id, name: w.name, target_url: w.target_url,
          events: w.events, is_active: w.is_active,
          failure_count: w.failure_count,
          last_triggered_at: w.last_triggered_at&.iso8601,
          created_at: w.created_at.iso8601
          # secret is NEVER returned
        }
      end

      def require_owner!
        render json: { error: "Owner access required" }, status: :forbidden unless current_user.owner_role?
      end
    end
  end
end
