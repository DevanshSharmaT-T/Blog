# frozen_string_literal: true

# Session-authenticated gallery image uploads for the blog post form.
# Production stores on Cloudinary, development on local public/uploads
# (both via ImageStorage). Distinct from Api::V1::ImagesController, which is
# token-authenticated and Cloudinary-only.
class BlogImagesController < ApplicationController
  before_action :authenticate_user!

  MAX_BYTES = 10.megabytes

  rescue_from CanCan::AccessDenied,             with: -> { render json: { error: "Not allowed." }, status: :forbidden }
  rescue_from ActiveRecord::RecordNotFound,     with: -> { render json: { error: "Not found." }, status: :not_found }
  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  # POST /blogs/:blog_id/images
  def create
    blog = Blog.not_deleted.accessible_by(current_ability).find(params[:blog_id])
    authorize! :update, blog

    file = params[:file]
    return render json: { error: "No file provided." }, status: :unprocessable_entity if file.blank?
    return render json: { error: "File too large (max 10 MB)." }, status: :unprocessable_entity if file.size.to_i > MAX_BYTES
    unless file.content_type.to_s.start_with?("image/")
      return render json: { error: "Only image uploads are allowed." }, status: :unprocessable_entity
    end

    data  = ImageStorage.store(file, user: current_user, folder: "myblog/blogs/#{blog.id}")
    image = blog.images.create!(data.merge(
      uploaded_by_id: current_user.id,
      display_order:  blog.images.count
    ))

    render json: { id: image.id, url: image.url, delete_url: blog_image_path(blog, image) }, status: :created
  rescue Cloudinary::Api::Error => e
    render json: { error: "Upload failed: #{e.message}" }, status: :unprocessable_entity
  end

  # DELETE /blogs/:blog_id/images/:id
  def destroy
    image = Image.find(params[:id])
    authorize! :destroy, image

    ImageStorage.remove(image.storage_key)
    image.destroy!

    render json: { ok: true }
  end

  # DELETE /blogs/:blog_id/images/unused
  # Removes gallery images whose URL is not referenced in the post content
  # (or set as the cover). `content` carries the editor's current text so
  # freshly-inserted-but-unsaved images are preserved.
  def unused
    blog = Blog.not_deleted.accessible_by(current_ability).find(params[:blog_id])
    authorize! :update, blog

    content = params[:content].to_s
    stale = blog.images.reject do |image|
      content.include?(image.url) || blog.cover_image_url == image.url
    end
    stale.select! { |image| can?(:destroy, image) }

    stale.each do |image|
      ImageStorage.remove(image.storage_key)
      image.destroy!
    end

    render json: { removed_ids: stale.map(&:id) }
  end
end
