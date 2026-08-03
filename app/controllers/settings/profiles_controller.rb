# frozen_string_literal: true

module Settings
  class ProfilesController < ApplicationController
    before_action :authenticate_user!

    def show
      @user = current_user
    end

    def update
      @user = current_user

      if params[:user][:email].present? && params[:user][:email] != @user.email
        if @user.update_with_password(profile_params_with_password)
          bypass_sign_in(@user)
          redirect_to settings_profile_path, notice: "Profile updated. A confirmation email has been sent to your new address."
        else
          render :show, status: :unprocessable_entity
        end
      elsif @user.update(profile_params)
        redirect_to settings_profile_path, notice: "Profile updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def profile_params
      params.require(:user).permit(:name, :username, :bio, :website_url, :avatar_url)
    end

    def profile_params_with_password
      params.require(:user).permit(:name, :username, :bio, :website_url, :avatar_url, :email, :current_password)
    end
  end
end
