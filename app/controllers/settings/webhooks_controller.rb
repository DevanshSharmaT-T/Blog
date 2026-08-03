# frozen_string_literal: true

module Settings
  class WebhooksController < ApplicationController
    before_action :require_owner!
    before_action :set_webhook, only: [ :show, :edit, :update, :destroy, :delivery_log, :retry_event ]

    def index
      @webhooks = current_user.api_webhooks.order(created_at: :desc)
    end

    def show
      @events = IntegrationEvent.joins(:integration)
                                .where(integrations: { provider: "webhooks" })
                                .where("payload->>'webhook_id' = ?", @webhook.id)
                                .last_50
    end

    def new
      @webhook = ApiWebhook.new(is_active: true)
    end

    def create
      @webhook = current_user.api_webhooks.build(webhook_params)
      @webhook.secret = SecureRandom.hex(32)

      if @webhook.save
        redirect_to settings_webhooks_path, notice: "Webhook created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @webhook.update(webhook_params.except(:secret))
        redirect_to settings_webhooks_path, notice: "Webhook updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @webhook.destroy!
      redirect_to settings_webhooks_path, notice: "Webhook deleted."
    end

    def delivery_log
      @events = IntegrationEvent.joins(:integration)
                                .where("payload->>'webhook_id' = ?", @webhook.id)
                                .last_50
    end

    def retry_event
      event = IntegrationEvent.find(params[:event_id])
      WebhookDispatchJob.perform_later(event.event_type, event.payload["body"])
      redirect_to delivery_log_settings_webhook_path(@webhook), notice: "Event queued for retry."
    end

    private

    def set_webhook
      @webhook = current_user.api_webhooks.find(params[:id])
    end

    def webhook_params
      params.require(:api_webhook).permit(:name, :target_url, :is_active, events: [])
    end

    def require_owner!
      unless current_user.owner_role?
        redirect_to root_path, alert: "Only the owner can manage webhooks."
      end
    end
  end
end
