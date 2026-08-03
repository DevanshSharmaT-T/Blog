# frozen_string_literal: true

module Api
  module V1
    class UserSocialsController < BaseController
      def index
        socials = current_user.user_socials.includes(:social_platform)
        render json: { socials: socials.map { |s| social_json(s) } }
      end

      def create
        platform = SocialPlatform.find(params[:social_platform_id])
        social = current_user.user_socials.build(
          social_platform: platform,
          handle: params[:handle],
          profile_url: params[:profile_url],
          is_public: params.fetch(:is_public, true)
        )
        social.access_token  = params[:access_token]  if params[:access_token].present?
        social.refresh_token = params[:refresh_token] if params[:refresh_token].present?

        if social.save
          render json: { social: social_json(social) }, status: :created
        else
          render json: { errors: social.errors.as_json }, status: :unprocessable_entity
        end
      end

      def destroy
        social = current_user.user_socials.find(params[:id])
        social.destroy!
        render json: { message: "Disconnected." }
      end

      private

      def social_json(s)
        {
          id: s.id, handle: s.handle, profile_url: s.profile_url,
          follower_count: s.follower_count, is_verified: s.is_verified,
          is_public: s.is_public, last_synced_at: s.last_synced_at&.iso8601,
          platform: { id: s.social_platform.id, name: s.social_platform.name, slug: s.social_platform.slug }
          # access_token and refresh_token are NEVER returned
        }
      end
    end
  end
end
