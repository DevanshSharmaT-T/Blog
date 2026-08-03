# frozen_string_literal: true

require "fileutils"

# Shared image storage used by both session-authenticated direct uploads
# (cover images, avatars via UploadsController) and the post gallery / inline
# editor uploads (BlogImagesController).
#
# Production stores on Cloudinary; development/test stores under public/uploads
# so the app works fully offline. Files larger than 5 MB are compressed
# (downscaled + re-encoded) before storage. Returns a normalized metadata hash
# so callers can persist it onto an Image record.
module ImageStorage
  module_function

  COMPRESS_THRESHOLD = 5.megabytes
  MAX_DIMENSION      = 2000
  QUALITY            = 80
  COMPRESSIBLE       = %w[image/jpeg image/png image/webp].freeze

  # `io` holds the underlying File/Tempfile so it isn't garbage-collected (and
  # its backing file unlinked) before the caller finishes reading `path`.
  Prepared = Struct.new(:io, :path, :content_type, :size, :original_filename, keyword_init: true)

  # Store an uploaded file and return:
  #   { url:, storage_key:, mime_type:, file_size_bytes:, width_px:, height_px: }
  def store(file, user:, folder: nil)
    prepared = prepare(file)
    Rails.env.production? ? store_cloudinary(prepared, folder: folder) : store_locally(prepared, user: user)
  end

  # Remove a previously stored file by its storage_key (no-op if missing).
  def remove(storage_key)
    return if storage_key.blank?

    if Rails.env.production?
      Cloudinary::Uploader.destroy(storage_key)
    elsif storage_key.start_with?("/uploads/")
      path = Rails.root.join("public", storage_key.delete_prefix("/"))
      File.delete(path) if File.exist?(path)
    end
  end

  def store_cloudinary(prepared, folder: nil)
    folder ||= "myblog/uploads"
    result = Cloudinary::Uploader.upload(prepared.path, folder: folder, use_filename: true, unique_filename: true)
    {
      url:             result["secure_url"],
      storage_key:     result["public_id"],
      mime_type:       result["format"] ? "image/#{result['format']}" : nil,
      file_size_bytes: result["bytes"],
      width_px:        result["width"],
      height_px:       result["height"]
    }
  end

  # Save under public/uploads/<user_id>/ and return a local URL. The storage_key
  # mirrors the URL so #remove can locate and delete the file later.
  def store_locally(prepared, user:)
    ext  = File.extname(prepared.original_filename.to_s)
    ext  = ".#{prepared.content_type.to_s.split('/').last}" if ext.blank?
    base = File.basename(prepared.original_filename.to_s, ext).parameterize.presence || "image"
    filename = "#{base}-#{SecureRandom.hex(6)}#{ext}"

    dir = Rails.root.join("public", "uploads", user.id.to_s)
    FileUtils.mkdir_p(dir)
    File.binwrite(dir.join(filename), File.binread(prepared.path))

    url = "/uploads/#{user.id}/#{filename}"
    {
      url:             url,
      storage_key:     url,
      mime_type:       prepared.content_type.presence,
      file_size_bytes: prepared.size,
      width_px:        nil,
      height_px:       nil
    }
  end

  # Compress oversized images (downscale to MAX_DIMENSION + re-encode at QUALITY).
  # Falls back to the original on anything non-compressible or on error.
  def prepare(file)
    original = Prepared.new(
      io:                file.tempfile,
      path:              file.tempfile.path,
      content_type:      file.content_type,
      size:              file.size,
      original_filename: file.original_filename
    )
    return original if file.size.to_i <= COMPRESS_THRESHOLD || COMPRESSIBLE.exclude?(file.content_type)

    begin
      require "image_processing/mini_magick"
      processed = ImageProcessing::MiniMagick
        .source(file.tempfile)
        .resize_to_limit(MAX_DIMENSION, MAX_DIMENSION)
        .saver(quality: QUALITY)
        .call

      processed_size = File.size(processed.path)
      return original if processed_size >= file.size.to_i

      Prepared.new(
        io:                processed,
        path:              processed.path,
        content_type:      file.content_type,
        size:              processed_size,
        original_filename: file.original_filename
      )
    rescue StandardError => e
      Rails.logger.warn("[ImageStorage] compression failed, using original: #{e.message}")
      original
    end
  end
end
