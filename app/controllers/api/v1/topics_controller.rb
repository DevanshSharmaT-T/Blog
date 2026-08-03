# frozen_string_literal: true

module Api
  module V1
    class TopicsController < BaseController
      skip_before_action :authenticate_api_user!, only: [ :index ]
      before_action :set_topic, only: [ :show, :update, :destroy ]

      def index
        @topics = Topic.active.includes(:sub_topics).by_name
        render json: { topics: @topics.map { |t| topic_json(t) } }
      end

      def create
        authorize! :create, Topic
        @topic = Topic.new(topic_params)
        if @topic.save
          render json: { topic: topic_json(@topic) }, status: :created
        else
          render json: { errors: @topic.errors.as_json }, status: :unprocessable_entity
        end
      end

      def update
        authorize! :update, @topic
        if @topic.update(topic_params)
          render json: { topic: topic_json(@topic) }
        else
          render json: { errors: @topic.errors.as_json }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize! :destroy, @topic
        @topic.update!(is_active: false)
        render json: { message: "Topic deactivated." }
      end

      private

      def set_topic
        @topic = Topic.find(params[:id])
      end

      def topic_params
        params.require(:topic).permit(:name, :slug, :description, :color_hex, :icon_name, :parent_id)
      end

      def topic_json(topic)
        {
          id:          topic.id,
          name:        topic.name,
          slug:        topic.slug,
          description: topic.description,
          color_hex:   topic.color_hex,
          icon_name:   topic.icon_name,
          post_count:  topic.post_count,
          parent_id:   topic.parent_id
        }
      end
    end
  end
end
