# frozen_string_literal: true

class TopicsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index, :show ]
  before_action :set_topic, only: [ :show, :edit, :update, :destroy ]

  def index
    @topics = Topic.active.root_level.includes(:sub_topics).by_name
  end

  def show
    @pagy, @blogs = pagy(Blog.visible.joins(:blog_topics)
                              .where(blog_topics: { topic_id: @topic.id })
                              .recent)
  end

  def new
    authorize! :create, Topic
    @topic = Topic.new
    @parent_topics = Topic.active.root_level.by_name
  end

  def create
    authorize! :create, Topic
    @topic = Topic.new(topic_params)

    if @topic.save
      redirect_to topics_path, notice: "Topic \"#{@topic.name}\" created."
    else
      @parent_topics = Topic.active.root_level.by_name
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize! :update, @topic
    @parent_topics = Topic.active.root_level.where.not(id: @topic.id).by_name
  end

  def update
    authorize! :update, @topic

    if @topic.update(topic_params)
      redirect_to topics_path, notice: "Topic updated."
    else
      @parent_topics = Topic.active.root_level.by_name
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @topic
    @topic.update!(is_active: false)
    redirect_to topics_path, notice: "Topic deactivated."
  end

  private

  def set_topic
    @topic = Topic.find_by!(slug: params[:id]) || Topic.find(params[:id])
  end

  def topic_params
    params.require(:topic).permit(:name, :slug, :description, :color_hex, :icon_name, :parent_id, :is_active)
  end
end
