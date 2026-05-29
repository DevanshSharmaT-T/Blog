# frozen_string_literal: true

class Blog < ApplicationRecord
  # ─── Enums ──────────────────────────────────────────────────────────────────
  enum :status, {
    draft:     "draft",
    review:    "review",
    scheduled: "scheduled",
    published: "published",
    archived:  "archived"
  }, suffix: true

  enum :content_format, { markdown: "markdown", html: "html" }, suffix: true

  # ─── Associations ────────────────────────────────────────────────────────────
  belongs_to :author,   class_name: "User", foreign_key: :author_id
  belongs_to :template, optional: true

  has_many :blog_topics,    dependent: :destroy
  has_many :topics,         through: :blog_topics
  has_many :images,         dependent: :destroy
  has_many :blog_analytics, dependent: :destroy
  has_many :integration_events, dependent: :nullify

  # ─── Validations ─────────────────────────────────────────────────────────────
  validates :title,          presence: true, length: { maximum: 255 }
  validates :slug,           presence: true, uniqueness: true, length: { maximum: 255 },
                             format: { with: /\A[a-z0-9-]+\z/, message: "must be lowercase with hyphens only" }
  validates :content,        presence: true, unless: :draft_status?
  validates :content_format, presence: true
  validates :status,         presence: true
  validates :seo_title,      length: { maximum: 70 }, allow_blank: true
  validates :seo_description, length: { maximum: 160 }, allow_blank: true

  # ─── Callbacks ───────────────────────────────────────────────────────────────
  before_validation :generate_slug, if: -> { slug.blank? && title.present? }
  before_save       :calculate_word_count
  before_save       :calculate_reading_time
  after_save        :run_scoring, if: :saved_change_to_content?

  # ─── Scopes ───────────────────────────────────────────────────────────────────
  scope :not_deleted,  -> { where(deleted_at: nil) }
  scope :visible,      -> { not_deleted.where(status: :published) }
  scope :featured,     -> { visible.where(featured: true) }
  scope :by_author,    ->(author) { where(author: author) }
  scope :recent,       -> { order(published_at: :desc) }
  scope :by_status,    ->(s) { where(status: s) }

  # ─── Ransack Allowlist ───────────────────────────────────────────────────────
  def self.ransackable_attributes(_auth_object = nil)
    %w[title slug status content excerpt seo_title seo_description
       word_count seo_score readability_score promotion_score
       featured allow_comments published_at created_at updated_at
       author_id template_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[author topics template]
  end

  # ─── Instance Methods ─────────────────────────────────────────────────────────
  def soft_delete!
    update!(deleted_at: Time.current, status: :archived)
  end

  def deleted?
    deleted_at.present?
  end

  def publish!
    update!(status: :published, published_at: Time.current, scheduled_at: nil)
  end

  def schedule!(publish_at)
    update!(status: :scheduled, scheduled_at: publish_at)
  end

  def submit_for_review!
    update!(status: :review)
  end

  private

  def generate_slug
    base = title.parameterize
    candidate = base
    counter = 1
    while Blog.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{counter}"
      counter += 1
    end
    self.slug = candidate
  end

  def calculate_word_count
    self.word_count = content.to_s.split.size
  end

  def calculate_reading_time
    self.reading_time_mins = [ (word_count.to_i / 200.0).ceil, 1 ].max
  end

  def run_scoring
    scores = ScoringService.new(self).call
    # Use update_columns to avoid triggering callbacks again
    update_columns(
      seo_score:          scores[:seo_score],
      readability_score:  scores[:readability_score],
      promotion_score:    scores[:promotion_score]
    )
  end
end
