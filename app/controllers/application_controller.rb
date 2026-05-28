# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend

  protect_from_forgery with: :exception

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html do
        flash[:alert] = "You are not authorized to perform this action."
        redirect_back(fallback_location: root_path)
      end
      format.json { render json: { error: exception.message }, status: :forbidden }
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.html do
        flash[:alert] = "Record not found."
        redirect_back(fallback_location: root_path)
      end
      format.json { render json: { error: "Not found" }, status: :not_found }
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,     keys: [ :name, :role ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :avatar_url, :bio, :website_url ])
  end

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end
end
