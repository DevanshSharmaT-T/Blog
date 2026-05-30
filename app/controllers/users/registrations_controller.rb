# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :configure_sign_up_params, only: [:create]
    before_action :configure_account_update_params, only: [:update]

    def after_sign_up_path_for(resource)
      blogs_path
    end

    def after_update_path_for(resource)
      settings_profile_path
    end

    protected

    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :username])
    end

    def configure_account_update_params
      devise_parameter_sanitizer.permit(:account_update, keys: [:name, :username, :avatar_url, :bio, :website_url])
    end
  end
end
