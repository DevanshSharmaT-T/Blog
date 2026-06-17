# frozen_string_literal: true

# Handles unmatched URLs (the routes.rb catch-all). Instead of a static 404 page,
# redirect the visitor to a safe in-app page. Skips auth/CSRF since it can be hit by
# any unauthenticated request and any HTTP verb.
class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_forgery_protection

  def not_found
    respond_to do |format|
      format.json { render json: { error: "Not found" }, status: :not_found }
      format.any  { redirect_to safe_fallback_path, alert: "That page doesn’t exist — here’s a good place to start." }
    end
  end
end
