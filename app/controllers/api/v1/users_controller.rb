# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      def show
        render json: { user: user_json(current_user) }
      end

      def update
        if current_user.update(user_params)
          render json: { user: user_json(current_user) }
        else
          render json: { errors: current_user.errors.as_json }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:name, :bio, :avatar_url, :website_url)
      end

      def user_json(u)
        {
          id: u.id, name: u.name, email: u.email, role: u.role,
          avatar_url: u.avatar_url, bio: u.bio, website_url: u.website_url,
          is_active: u.is_active, email_verified_at: u.email_verified_at&.iso8601,
          last_login_at: u.last_login_at&.iso8601, created_at: u.created_at.iso8601
        }
      end
    end
  end
end
