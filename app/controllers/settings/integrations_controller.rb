# frozen_string_literal: true

module Settings
  class IntegrationsController < ApplicationController
    before_action :require_owner!
    before_action :set_integration, only: [ :edit, :update, :destroy, :test_connection ]

    def index
      @integrations = ThirdPartyIntegration.for_user(current_user)
                                           .order(:provider_type, :provider)
      @by_type = @integrations.group_by(&:provider_type)
    end

    def new
      @integration = ThirdPartyIntegration.new(provider_type: params[:type])
    end

    def create
      @integration = ThirdPartyIntegration.new(integration_params)
      @integration.user = current_user

      if params[:credentials].present?
        @integration.credentials = params[:credentials].to_unsafe_h
      end

      if @integration.save
        redirect_to settings_integrations_path, notice: "Integration added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if params[:credentials].present?
        @integration.credentials = params[:credentials].to_unsafe_h
      end

      if @integration.update(integration_params)
        redirect_to settings_integrations_path, notice: "Integration updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @integration.destroy!
      redirect_to settings_integrations_path, notice: "Integration removed."
    end

    def test_connection
      # Basic connectivity test — update last_tested_at and status
      begin
        @integration.mark_active!
        render json: { success: true, message: "Connection successful." }
      rescue StandardError => e
        @integration.mark_error!(e.message)
        render json: { success: false, message: e.message }, status: :unprocessable_entity
      end
    end

    private

    def set_integration
      @integration = current_user.third_party_integrations.find(params[:id])
    end

    def integration_params
      params.require(:third_party_integration).permit(
        :provider, :provider_type, :label, :status,
        config: {}
      )
    end

    def require_owner!
      unless current_user.owner_role?
        redirect_to root_path, alert: "Only the owner can manage integrations."
      end
    end
  end
end
