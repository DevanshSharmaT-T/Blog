# frozen_string_literal: true

class BlogTopic < ApplicationRecord
  self.primary_key = nil  # composite PK managed by DB

  # ─── Associations ────────────────────────────────────────────────────────────
  belongs_to :blog
  belongs_to :topic

  # ─── Callbacks ───────────────────────────────────────────────────────────────
  after_create  :increment_topic_count
  after_destroy :decrement_topic_count

  private

  def increment_topic_count
    topic.increment!(:post_count)
  end

  def decrement_topic_count
    topic.decrement!(:post_count)
  end
end
