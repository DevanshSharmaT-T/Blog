# frozen_string_literal: true

# Handles unmatched URLs (the routes.rb catch-all). A real browser navigation gets
# bounced to a safe in-app page; asset fetches, JSON/API calls, and non-GET verbs get
# an honest 404. Skips auth/CSRF since it can be hit by any unauthenticated request
# and any HTTP verb.
class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_forgery_protection

  def not_found
    if request.format.json?
      render json: { error: "Not found" }, status: :not_found
    elsif browser_navigation?
      redirect_to safe_fallback_path, alert: "That page doesn’t exist — here’s a good place to start."
    else
      head :not_found
    end
  end
end
