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

  # Content moderation lifecycle (independent of the publishing `status`):
  #   clean    — no banned/sensitive terms detected
  #   flagged  — terms detected; cannot be published until an admin approves
  #   approved — an admin reviewed and cleared it; publishes normally
  enum :moderation_state, { clean: "clean", flagged: "flagged", approved: "approved" },
       prefix: :moderation

  # ─── Associations ────────────────────────────────────────────────────────────
  belongs_to :author,      class_name: "User", foreign_key: :author_id
  belongs_to :template,    optional: true
  belongs_to :moderated_by, class_name: "User", optional: true

  has_many :blog_topics,    dependent: :destroy
  has_many :topics,         through: :blog_topics
  has_many :images,         dependent: :destroy
  has_many :blog_analytics, dependent: :destroy
  has_many :integration_events, dependent: :nullify

  # ─── Validations ─────────────────────────────────────────────────────────────
  validates :title,          presence: true, length: { maximum: 255 }
  validates :slug,           presence: true, uniqueness: { scope: :author_id }, length: { maximum: 255 },
                             format: { with: /\A[a-z0-9-]+\z/, message: "must be lowercase with hyphens only" }
  validates :content,        presence: true, unless: :draft_status?
  validates :content_format, presence: true
  validates :status,         presence: true
  validates :seo_title,      length: { maximum: 70 }, allow_blank: true
  validates :seo_description, length: { maximum: 160 }, allow_blank: true
  validate  :flagged_content_cannot_go_public

  # ─── Callbacks ───────────────────────────────────────────────────────────────
  before_validation :generate_slug, if: -> { slug.blank? && title.present? }
  before_validation :scan_for_banned_content
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
  scope :flagged,      -> { where(moderation_state: :flagged) }

  # ─── Ransack Allowlist ───────────────────────────────────────────────────────
  def self.ransackable_attributes(_auth_object = nil)
    %w[title slug status content excerpt seo_title seo_description
       word_count seo_score readability_score promotion_score
       featured allow_comments published_at created_at updated_at
       author_id template_id moderation_state]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[author topics template]
  end

  # ─── Instance Methods ─────────────────────────────────────────────────────────
  def soft_delete!
    update_columns(deleted_at: Time.current, status: :archived, updated_at: Time.current)
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

  # Admin action: clear a flagged blog so its author can publish it. Recorded
  # for an audit trail. A later edit to the title/excerpt/content re-scans and
  # may flag it again (see #scan_for_banned_content).
  def approve_moderation!(by:, note: nil)
    update!(moderation_state: :approved, moderated_by: by,
            moderated_at: Time.current, moderation_note: note.presence)
  end

  # Admin action: send a flagged blog back to the author with an optional note.
  def reject_moderation!(by:, note: nil)
    update!(moderation_state: :flagged, status: :draft, moderated_by: by,
            moderated_at: Time.current, moderation_note: note.presence)
  end

  # Canonical public URL: /@<username>/blog/<slug> on the configured apex host.
  #
  # ── PATH-BASED MODE (active) ──────────────────────────────────────────────────
  def public_url
    Rails.application.routes.url_helpers.public_blog_url(username: author.username, slug: slug)
  end
  #
  # ── SUBDOMAIN MODE (disabled) ── requires a wildcard domain; see config/routes.rb.
  # def public_url
  #   opts = Rails.application.routes.default_url_options
  #   Rails.application.routes.url_helpers.public_blog_url(
  #     slug: slug, host: "#{author.username}.#{opts[:host]}", port: opts[:port]
  #   )
  # end

  # Rich payload for the `blog.published` webhook so connected automations
  # (Zapier/Make/n8n, etc.) have everything needed to announce the post.
  def published_webhook_payload
    {
      blog_id:         id,
      title:           title,
      slug:            slug,
      url:             public_url,
      excerpt:         excerpt,
      cover_image_url: cover_image_url,
      topics:          topics.map(&:name),
      author_id:       author_id,
      author_name:     author.name,
      author_username: author.username,
      author_socials:  author.user_socials.includes(:social_platform).where(is_public: true)
                              .map { |s| { platform: s.social_platform.slug, handle: s.handle } },
      published_at:    published_at&.iso8601
    }
  end

  private

  # Re-scan the user-authored fields whenever any of them change. Matches flag
  # the blog (and reset a stale approval, since the content is now different);
  # a clean edit clears the flag. Unchanged content leaves the state untouched
  # so an admin's approval sticks across unrelated saves (e.g. publishing).
  def scan_for_banned_content
    return unless will_save_change_to_title? ||
                  will_save_change_to_excerpt? ||
                  will_save_change_to_content?

    matches = ContentModeration.scan([ title, excerpt, content ].join("\n"))

    if matches.any?
      self.moderation_state = :flagged
      self.moderation_flagged_terms = matches.join(", ")
      self.moderated_by_id = nil
      self.moderated_at    = nil
    else
      self.moderation_state = :clean
      self.moderation_flagged_terms = nil
    end
  end

  # A flagged blog must not become publicly visible. It can still be saved as a
  # draft or submitted for review; an admin approval lifts this block.
  def flagged_content_cannot_go_public
    return unless moderation_flagged?
    return unless published_status? || scheduled_status?

    errors.add(:base,
               "This post contains flagged content (#{moderation_flagged_terms}) and " \
               "must be approved by an admin before it can be published. " \
               "Submit it for review to request approval.")
  end

  def generate_slug
    base = title.parameterize
    candidate = base
    counter = 1
    # Slugs are unique per author, so only check collisions within this author's blogs.
    while Blog.where(author_id: author_id).where.not(id: id).exists?(slug: candidate)
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
