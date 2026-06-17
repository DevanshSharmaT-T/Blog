# frozen_string_literal: true

class BlogsController < ApplicationController
  include Pagy::Backend

  skip_before_action :authenticate_user!, only: [ :index, :show, :listing, :feed ]

  before_action :set_blog, only: [ :show, :edit, :update, :destroy, :publish, :archive, :submit_review, :schedule, :approve_moderation, :reject_moderation ]
  before_action :authorize_blog!, only: [ :edit, :update, :destroy, :publish, :archive, :submit_review, :schedule ]

  # GET /blog/:slug (public)
  def show
    unless @blog.published_status? && !@blog.deleted?
      if current_user&.can?(:edit, @blog)
        # Authors/admins can preview unpublished posts
      else
        redirect_to root_path, alert: "Post not found." and return
      end
    end

    if @blog.published_status? && !@blog.deleted?
      BlogAnalytics::RecordViewJob.perform_later(blog_id: @blog.id)
    end

    @related_blogs = Blog.visible
                         .where.not(id: @blog.id)
                         .joins(:topics)
                         .where(topics: { id: @blog.topic_ids })
                         .distinct
                         .recent
                         .limit(3)
  end

  # GET /blog (public archive — paginated listing of published blogs)
  def listing
    @tab = params[:tab].presence
    scope = Blog.visible.includes(:author, :topics).order(published_at: :desc)
    scope = scope.joins(:topics).where(topics: { id: params[:topic_id] }) if params[:topic_id].present?
    # "From the developers" tab — posts authored by the site's owners/admins.
    scope = scope.joins(:author).where(users: { role: %w[owner admin] }) if @tab == "developers"
    @q = scope.ransack(params[:q])
    @pagy, @blogs = pagy(@q.result(distinct: true), items: 12)
    @topics = Topic.active.by_name
  end

  # GET /blog/feed.atom — Atom feed of the 25 most recent published posts
  def feed
    @blogs = Blog.visible.includes(:author, :topics).order(published_at: :desc).limit(25)
    respond_to do |format|
      format.atom
    end
  end

  # GET /blogs (dashboard listing)
  def index
    @q = Blog.not_deleted
             .accessible_by(current_ability)
             .includes(:author, :topics)
             .ransack(params[:q])

    @q.sorts = "created_at desc" if @q.sorts.empty?
    @pagy, @blogs = pagy(@q.result(distinct: true))
  end

  # GET /blogs/new
  def new
    @blog = Blog.new
    @step = :topics
  end

  # POST /blogs
  def create
    @blog = Blog.new(blog_params)
    @blog.author = current_user

    if @blog.save
      handle_topics_assignment
      redirect_to edit_blog_path(@blog, step: :content),
                  notice: "Blog created! Continue editing."
    else
      @step = :topics
      @topics = Topic.active.by_name
      render :new, status: :unprocessable_entity
    end
  end

  # GET /blogs/:id/edit
  def edit
    @step = params[:step]&.to_sym || :topics
    load_step_data
  end

  # PATCH /blogs/:id
  def update
    @step = params[:step]&.to_sym || :content

    if @blog.update(blog_params)
      handle_topics_assignment if @step == :topics
      next_step = next_step_for(@step)
      if next_step
        redirect_to edit_blog_path(@blog, step: next_step), notice: "Saved!"
      else
        redirect_to blog_path(@blog), notice: "Blog updated successfully."
      end
    else
      load_step_data
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /blogs/:id
  def destroy
    @blog.soft_delete!
    WebhookDispatchJob.perform_later("blog.deleted", { blog_id: @blog.id, title: @blog.title })
    redirect_to blogs_path, notice: "Blog deleted."
  end

  # PATCH /blogs/:id/publish
  def publish
    @blog.publish!
    WebhookDispatchJob.perform_later("blog.published", @blog.published_webhook_payload)
    redirect_to blogs_path, notice: "\"#{@blog.title}\" is now live!"
  end

  # PATCH /blogs/:id/archive
  def archive
    @blog.update!(status: :archived)
    WebhookDispatchJob.perform_later("blog.archived", { blog_id: @blog.id, title: @blog.title })
    redirect_to blogs_path, notice: "Blog archived."
  end

  # PATCH /blogs/:id/submit_review
  def submit_review
    @blog.submit_for_review!
    redirect_to blogs_path, notice: "Blog submitted for review."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to edit_blog_path(@blog, step: :content),
                alert: "Can't submit for review: #{e.record.errors.full_messages.to_sentence}."
  end

  # POST /blogs/:id/schedule
  def schedule
    scheduled_at = Time.zone.parse(params[:scheduled_at])
    if scheduled_at&.future?
      @blog.schedule!(scheduled_at)
      redirect_to blogs_path, notice: "Blog scheduled for #{scheduled_at.strftime('%b %d, %Y at %I:%M %p')}."
    else
      redirect_to edit_blog_path(@blog, step: :review), alert: "Scheduled time must be in the future."
    end
  end

  # GET /blogs/moderation_queue (admins/owners) — posts flagged for banned content
  def moderation_queue
    authorize! :moderate, Blog
    @pagy, @blogs = pagy(
      Blog.not_deleted.flagged.includes(:author).order(updated_at: :desc)
    )
  end

  # PATCH /blogs/:id/approve_moderation (admins/owners)
  def approve_moderation
    authorize! :moderate, @blog
    @blog.approve_moderation!(by: current_user, note: params[:moderation_note])
    redirect_to moderation_queue_blogs_path,
                notice: "\"#{@blog.title}\" approved. The author can now publish it."
  end

  # PATCH /blogs/:id/reject_moderation (admins/owners)
  def reject_moderation
    authorize! :moderate, @blog
    @blog.reject_moderation!(by: current_user, note: params[:moderation_note])
    redirect_to moderation_queue_blogs_path,
                notice: "\"#{@blog.title}\" returned to its author."
  end

  # POST /blogs/bulk_action
  def bulk_action
    blog_ids = params[:blog_ids] || []
    blogs = Blog.accessible_by(current_ability).where(id: blog_ids)

    case params[:action_type]
    when "publish"
      blogs.each(&:publish!)
    when "archive"
      blogs.update_all(status: :archived)
    when "delete"
      blogs.each(&:soft_delete!)
    end

    redirect_to blogs_path, notice: "Bulk action applied."
  end

  private

  def set_blog
    @blog = if action_name == "show"
              # Public posts: /@<username>/blog/<slug>. Visibility/preview enforced in #show.
              #
              # ── PATH-BASED MODE (active) ── author from the :username path segment:
              username = params[:username]
              # ── SUBDOMAIN MODE (disabled) ── derive author from the apex host-suffix:
              # apex     = Rails.application.routes.default_url_options[:host].to_s
              # username = request.host.to_s.delete_suffix(".#{apex}")
              author   = User.find_by!(username: username)
              author.blogs.not_deleted.includes(:template, :author, :topics).find_by!(slug: params[:slug])
            else
              Blog.not_deleted.find(params[:id])
            end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_url(host: Rails.application.routes.default_url_options[:host]), alert: "Blog not found." and return
  end

  def authorize_blog!
    authorize! :update, @blog
  end

  def blog_params
    params.require(:blog).permit(
      :title, :slug, :excerpt, :content, :content_format,
      :cover_image_url, :seo_title, :seo_description,
      :template_id, :featured, :allow_comments
    )
  end

  def handle_topics_assignment
    return unless params[:blog][:topic_ids]
    @blog.blog_topics.destroy_all
    topic_ids = params[:blog][:topic_ids].reject(&:blank?)
    topic_ids.each do |tid|
      @blog.blog_topics.create!(topic_id: tid)
    end
  end

  def load_step_data
    case @step
    when :topics
      @topics = Topic.active.by_name
      @selected_topic_ids = @blog.topic_ids
    when :content
      @templates = Template.active
    when :template
      @templates = Template.active
    when :review
      # All data loaded via @blog associations
    end
  end

  def next_step_for(step)
    steps = [ :topics, :content, :template, :review ]
    idx = steps.index(step)
    steps[idx + 1] if idx && idx < steps.length - 1
  end
end
