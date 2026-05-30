# frozen_string_literal: true

require "fileutils"

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

    payload = Rails.env.production? ? upload_to_cloudinary(file) : store_locally(file)
    render json: payload, status: :created
  rescue Cloudinary::Api::Error => e
    render json: { error: "Upload failed: #{e.message}" }, status: :unprocessable_entity
  end

  private

  def upload_to_cloudinary(file)
    folder = params[:folder].presence || "myblog/uploads/#{current_user.id}"
    result = Cloudinary::Uploader.upload(file, folder: folder, use_filename: true, unique_filename: true)
    {
      url:       result["secure_url"],
      public_id: result["public_id"],
      width:     result["width"],
      height:    result["height"]
    }
  end

  # Save the upload under public/uploads/<user_id>/ and return a local URL.
  def store_locally(file)
    ext  = File.extname(file.original_filename.to_s)
    ext  = ".#{file.content_type.to_s.split('/').last}" if ext.blank?
    base = File.basename(file.original_filename.to_s, ext).parameterize.presence || "image"
    filename = "#{base}-#{SecureRandom.hex(6)}#{ext}"

    dir = Rails.root.join("public", "uploads", current_user.id.to_s)
    FileUtils.mkdir_p(dir)
    File.binwrite(dir.join(filename), file.read)

    { url: "/uploads/#{current_user.id}/#{filename}" }
  end
end
