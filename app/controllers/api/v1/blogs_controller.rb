# frozen_string_literal: true

module Api
  module V1
    class BlogsController < BaseController
      before_action :set_blog, only: [ :show, :update, :destroy, :publish, :schedule, :submit_review ]

      # GET /api/v1/blogs
      def index
        scope = Blog.not_deleted.accessible_by(current_ability).includes(:author, :topics)

        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(author_id: params[:author_id]) if params[:author_id].present?
        scope = scope.joins(:blog_topics).where(blog_topics: { topic_id: params[:topic_id] }) if params[:topic_id].present?
        scope = scope.where("title ILIKE ?", "%#{params[:q]}%") if params[:q].present?
        scope = scope.order(created_at: :desc)

        result = paginate(scope)
        render json: {
          blogs: result[:records].map { |b| blog_json(b) },
          meta:  result[:meta]
        }
      end

      # GET /api/v1/blogs/:id
      def show
        render json: { blog: blog_json(@blog, full: true) }
      end

      # POST /api/v1/blogs
      def create
        authorize! :create, Blog
        @blog = Blog.new(blog_params)
        @blog.author = current_user

        if @blog.save
          assign_topics
          render json: { blog: blog_json(@blog, full: true) }, status: :created
        else
          render json: { errors: @blog.errors.as_json }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/blogs/:id
      def update
        authorize! :update, @blog

        if @blog.update(blog_params)
          assign_topics
          WebhookDispatchJob.perform_later("blog.updated", { blog_id: @blog.id, title: @blog.title })
          render json: { blog: blog_json(@blog, full: true) }
        else
          render json: { errors: @blog.errors.as_json }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/blogs/:id
      def destroy
        authorize! :destroy, @blog
        @blog.soft_delete!
        WebhookDispatchJob.perform_later("blog.deleted", { blog_id: @blog.id })
        render json: { message: "Blog deleted." }
      end

      # POST /api/v1/blogs/:id/publish
      def publish
        authorize! :publish, @blog
        @blog.publish!
        WebhookDispatchJob.perform_later("blog.published", {
          blog_id:      @blog.id,
          title:        @blog.title,
          published_at: @blog.published_at.iso8601
        })
        render json: { blog: blog_json(@blog) }
      end

      # POST /api/v1/blogs/:id/schedule
      def schedule
        authorize! :schedule, @blog
        scheduled_at = Time.zone.parse(params[:scheduled_at].to_s)
        return render json: { error: "scheduled_at must be in the future" }, status: :unprocessable_entity unless scheduled_at&.future?

        @blog.schedule!(scheduled_at)
        render json: { blog: blog_json(@blog) }
      end

      # POST /api/v1/blogs/:id/submit_review
      def submit_review
        @blog.submit_for_review!
        render json: { blog: blog_json(@blog) }
      end

      private

      def set_blog
        @blog = Blog.not_deleted.find(params[:id])
        authorize! :read, @blog
      end

      def blog_params
        params.require(:blog).permit(
          :title, :slug, :excerpt, :content, :content_format,
          :cover_image_url, :seo_title, :seo_description,
          :template_id, :featured, :allow_comments
        )
      end

      def assign_topics
        return unless params[:topic_ids].present?
        @blog.blog_topics.destroy_all
        Array(params[:topic_ids]).each { |tid| @blog.blog_topics.create!(topic_id: tid) }
      end

      def blog_json(blog, full: false)
        data = {
          id:               blog.id,
          title:            blog.title,
          slug:             blog.slug,
          status:           blog.status,
          author:           { id: blog.author_id, name: blog.author.name },
          topics:           blog.topics.map { |t| { id: t.id, name: t.name, slug: t.slug } },
          word_count:       blog.word_count,
          reading_time_mins: blog.reading_time_mins,
          seo_score:        blog.seo_score,
          readability_score: blog.readability_score,
          promotion_score:  blog.promotion_score,
          published_at:     blog.published_at&.iso8601,
          created_at:       blog.created_at.iso8601,
          updated_at:       blog.updated_at.iso8601
        }

        if full
          data.merge!(
            excerpt:        blog.excerpt,
            content:        blog.content,
            content_format: blog.content_format,
            cover_image_url: blog.cover_image_url,
            seo_title:      blog.seo_title,
            seo_description: blog.seo_description,
            template_id:    blog.template_id,
            featured:       blog.featured,
            allow_comments: blog.allow_comments,
            scheduled_at:   blog.scheduled_at&.iso8601
          )
        end

        data
      end
    end
  end
end
