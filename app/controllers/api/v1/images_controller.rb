# frozen_string_literal: true

module Api
  module V1
    class ImagesController < BaseController
      # POST /api/v1/images — multipart upload to Cloudinary
      def create
        blog = Blog.find(params[:blog_id])
        authorize! :update, blog

        upload_result = Cloudinary::Uploader.upload(
          params[:file],
          folder:    "myblog/blogs/#{blog.id}",
          use_filename: true,
          unique_filename: true
        )

        @image = blog.images.create!(
          uploaded_by_id: current_user.id,
          url:            upload_result["secure_url"],
          storage_key:    upload_result["public_id"],
          mime_type:      upload_result["format"] ? "image/#{upload_result['format']}" : nil,
          file_size_bytes: upload_result["bytes"],
          width_px:       upload_result["width"],
          height_px:      upload_result["height"],
          alt_text:       params[:alt_text],
          caption:        params[:caption],
          display_order:  blog.images.count
        )

        render json: {
          id:    @image.id,
          url:   @image.url,
          width: @image.width_px,
          height: @image.height_px
        }, status: :created

      rescue Cloudinary::Api::Error => e
        render json: { error: "Upload failed: #{e.message}" }, status: :unprocessable_entity
      end

      # DELETE /api/v1/images/:id
      def destroy
        @image = Image.find(params[:id])
        authorize! :destroy, @image

        Cloudinary::Uploader.destroy(@image.storage_key) if @image.storage_key.present?
        @image.destroy!

        render json: { message: "Image deleted." }
      rescue Cloudinary::Api::Error => e
        render json: { error: "Cloudinary error: #{e.message}" }, status: :unprocessable_entity
      end
    end
  end
end
