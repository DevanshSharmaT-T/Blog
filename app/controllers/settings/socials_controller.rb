# frozen_string_literal: true

module Settings
  class SocialsController < ApplicationController
    def index
      @user_socials     = current_user.user_socials.includes(:social_platform).order("social_platforms.name")
      @social_platforms = SocialPlatform.active.order(:name)
      @connected_ids    = @user_socials.map(&:social_platform_id)
    end

    def create
      platform = SocialPlatform.find(params[:social_platform_id])
      @social  = current_user.user_socials.build(
        social_platform: platform,
        handle:          params[:handle],
        profile_url:     params[:profile_url],
        is_public:       params.fetch(:is_public, true)
      )

      if @social.save
        redirect_to settings_socials_path, notice: "#{platform.name} connected successfully."
      else
        @user_socials     = current_user.user_socials.includes(:social_platform)
        @social_platforms = SocialPlatform.active.order(:name)
        @connected_ids    = @user_socials.map(&:social_platform_id)
        flash.now[:alert] = @social.errors.full_messages.to_sentence
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      @social = current_user.user_socials.find(params[:id])
      platform_name = @social.platform_name
      @social.destroy!
      redirect_to settings_socials_path, notice: "#{platform_name} disconnected."
    end
  end
end
