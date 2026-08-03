# frozen_string_literal: true

module Api
  module V1
    class IntegrationsController < BaseController
      before_action :require_owner!
      before_action :set_integration, only: [ :show, :update, :destroy, :test ]

      def index
        integrations = ThirdPartyIntegration.for_user(current_user).order(:provider_type, :provider)
        render json: { integrations: integrations.map { |i| integration_json(i) } }
      end

      def create
        integration = ThirdPartyIntegration.new(integration_params)
        integration.user = current_user
        integration.credentials = JSON.parse(params[:credentials]) if params[:credentials].present?

        if integration.save
          render json: { integration: integration_json(integration) }, status: :created
        else
          render json: { errors: integration.errors.as_json }, status: :unprocessable_entity
        end
      end

      def update
        @integration.credentials = JSON.parse(params[:credentials]) if params[:credentials].present?
        if @integration.update(integration_params)
          render json: { integration: integration_json(@integration) }
        else
          render json: { errors: @integration.errors.as_json }, status: :unprocessable_entity
        end
      end

      def destroy
        @integration.destroy!
        render json: { message: "Integration removed." }
      end

      def test
        @integration.mark_active!
        render json: { success: true, last_tested_at: @integration.last_tested_at.iso8601 }
      rescue StandardError => e
        @integration.mark_error!(e.message)
        render json: { success: false, error: e.message }, status: :unprocessable_entity
      end

      private

      def set_integration
        @integration = current_user.third_party_integrations.find(params[:id])
      end

      def integration_params
        params.require(:third_party_integration).permit(:provider, :provider_type, :label, :status, config: {})
      end

      def integration_json(i)
        {
          id: i.id, provider: i.provider, provider_type: i.provider_type,
          label: i.label, status: i.status, config: i.config,
          last_tested_at: i.last_tested_at&.iso8601, error_message: i.error_message,
          created_at: i.created_at.iso8601
          # credentials are NEVER returned
        }
      end

      def require_owner!
        render json: { error: "Owner access required" }, status: :forbidden unless current_user.owner_role?
      end
    end
  end
end
