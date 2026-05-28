# frozen_string_literal: true

class UploadsController < ApplicationController
  before_action :authenticate_user!

  # POST /uploads — session-authenticated direct upload (cover images, avatars)
  def create
    file = params[:file]
    return render json: { error: "No file provided." }, status: :unprocessable_entity if file.blank?

    folder = params[:folder].presence || "myblog/uploads/#{current_user.id}"

    result = Cloudinary::Uploader.upload(
      file,
      folder: folder,
      use_filename: true,
      unique_filename: true
    )

    render json: {
      url:        result["secure_url"],
      public_id:  result["public_id"],
      width:      result["width"],
      height:     result["height"]
    }, status: :created
  rescue Cloudinary::Api::Error => e
    render json: { error: "Upload failed: #{e.message}" }, status: :unprocessable_entity
  end
end
