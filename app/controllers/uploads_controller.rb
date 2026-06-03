# frozen_string_literal: true

class UploadsController < ApplicationController
  before_action :authenticate_user!

  MAX_BYTES = 10.megabytes

  # POST /uploads — session-authenticated direct upload (cover images, avatars).
  # Production: Cloudinary CDN. Development/test: local public/uploads (no Cloudinary).
  def create
    file = params[:file]
    return render json: { error: "No file provided." }, status: :unprocessable_entity if file.blank?
    return render json: { error: "File too large (max 10 MB)." }, status: :unprocessable_entity if file.size.to_i > MAX_BYTES
    unless file.content_type.to_s.start_with?("image/")
      return render json: { error: "Only image uploads are allowed." }, status: :unprocessable_entity
    end

    folder = params[:folder].presence || "myblog/uploads/#{current_user.id}"
    payload = ImageStorage.store(file, user: current_user, folder: folder)
    render json: { url: payload[:url] }, status: :created
  rescue Cloudinary::Api::Error => e
    render json: { error: "Upload failed: #{e.message}" }, status: :unprocessable_entity
  end
end
