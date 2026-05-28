# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate_api_user!

      rescue_from CanCan::AccessDenied do |e|
        render json: { error: "Forbidden", message: e.message }, status: :forbidden
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: { error: "Not Found", message: e.message }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { error: "Validation Failed", errors: e.record.errors.as_json }, status: :unprocessable_entity
      end

      private

      def authenticate_api_user!
        authenticate_with_http_token do |token, _options|
          payload = JWT.decode(token, jwt_secret, true, algorithm: "HS256").first
          @current_user = User.active.find(payload["user_id"])
        rescue JWT::DecodeError, ActiveRecord::RecordNotFound
          nil
        end

        render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
      end

      def current_user
        @current_user
      end

      def current_ability
        @current_ability ||= Ability.new(current_user)
      end

      def jwt_secret
        ENV.fetch("JWT_SECRET") { Rails.application.secret_key_base }
      end

      def paginate(scope)
        page  = (params[:page] || 1).to_i
        limit = [ (params[:per_page] || 20).to_i, 100 ].min
        total = scope.count
        records = scope.offset((page - 1) * limit).limit(limit)
        {
          records: records,
          meta: {
            page: page,
            per_page: limit,
            total: total,
            total_pages: (total.to_f / limit).ceil
          }
        }
      end
    end
  end
end
