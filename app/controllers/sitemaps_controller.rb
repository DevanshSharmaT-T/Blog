# frozen_string_literal: true

class SitemapsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @blogs  = Blog.visible.order(published_at: :desc)
    @topics = Topic.active
    expires_in 1.hour, public: true
    respond_to do |format|
      format.xml
    end
  end
end
