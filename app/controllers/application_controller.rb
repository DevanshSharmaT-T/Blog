# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend

  protect_from_forgery with: :exception

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Registered FIRST so the more specific rescues below take precedence (Rails
  # matches the last-registered handler for a given exception class).
  rescue_from StandardError, with: :handle_unexpected_error

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

  # Last-resort handler for any otherwise-unrescued exception. Rather than stranding
  # the visitor on a static 500 page, log it and send them back to a safe in-app page.
  # Re-raised in dev/test so real errors stay visible and the test suite still fails.
  def handle_unexpected_error(exception)
    raise exception if Rails.env.local?

    Rails.logger.error("[Unhandled] #{exception.class}: #{exception.message}")
    Rails.logger.error(Array(exception.backtrace).first(15).join("\n"))

    respond_to do |format|
      format.json { render json: { error: "Something went wrong." }, status: :internal_server_error }
      format.any  { redirect_to safe_fallback_path, alert: "Something went wrong — we've brought you back to a safe page." }
    end
  rescue ActionController::UnknownFormat
    redirect_to safe_fallback_path, alert: "Something went wrong — we've brought you back to a safe page."
  end

  # Where to send a user after an error: their dashboard/blogs when signed in, root
  # otherwise. Mirrors after_sign_in_path_for; rescued so it can never itself raise.
  def safe_fallback_path
    if user_signed_in?
      (current_user.owner_role? || current_user.admin_role?) ? dashboard_path : blogs_path
    else
      root_path
    end
  rescue StandardError
    root_path
  end
end
