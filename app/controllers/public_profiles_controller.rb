# frozen_string_literal: true

# Public author profile, served at /@<username> (path-based; see config/routes.rb).
# The author is derived from the :username path segment, mirroring BlogsController#set_blog.
class PublicProfilesController < ApplicationController
  include Pagy::Backend

  skip_before_action :authenticate_user!, only: [ :show ]

  def show
    apex     = Rails.application.routes.default_url_options[:host].to_s
    # ── PATH-BASED MODE (active) ── author from the /@:username path segment:
    username = params[:username]
    # ── SUBDOMAIN MODE (disabled) ── derive author from the apex host-suffix:
    # username = request.host.to_s.delete_suffix(".#{apex}")
    @author  = User.active.find_by!(username: username)

    @pagy, @blogs = pagy(
      @author.blogs.visible.includes(:author, :topics).order(published_at: :desc),
      items: 9
    )
    @socials = @author.public_socials
  rescue ActiveRecord::RecordNotFound
    redirect_to root_url(host: apex), alert: "Profile not found." and return
  end
end
