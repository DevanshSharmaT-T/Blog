# frozen_string_literal: true

class ScheduledPublishJob < ApplicationJob
  queue_as :default

  def perform
    blogs = Blog.where(status: :scheduled)
                .where("scheduled_at <= ?", Time.current)
                .not_deleted

    blogs.find_each do |blog|
      blog.publish!
      WebhookDispatchJob.perform_later("blog.published", {
        blog_id:    blog.id,
        title:      blog.title,
        author_id:  blog.author_id,
        published_at: blog.published_at.iso8601
      })
    rescue StandardError => e
      Rails.logger.error "[ScheduledPublishJob] Failed to publish blog #{blog.id}: #{e.message}"
    end
  end
end
