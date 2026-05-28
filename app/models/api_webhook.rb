# frozen_string_literal: true

class ApiWebhook < ApplicationRecord
  SUPPORTED_EVENTS = %w[
    blog.published
    blog.updated
    blog.archived
    blog.deleted
    user.created
    analytics.synced
  ].freeze

  MAX_FAILURES = 5

  # ─── Associations ────────────────────────────────────────────────────────────
  belongs_to :user

  # ─── Validations ─────────────────────────────────────────────────────────────
  validates :name,       presence: true, length: { maximum: 120 }
  validates :target_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :secret_ciphertext, presence: true
  validates :events,     presence: true

  validate :validate_events_subset

  # ─── Encrypted Secret Accessor ───────────────────────────────────────────────
  def secret
    return nil if secret_ciphertext.blank?
    EncryptionService.decrypt(secret_ciphertext)
  rescue StandardError
    nil
  end

  def secret=(plaintext)
    self.secret_ciphertext = plaintext.present? ? EncryptionService.encrypt(plaintext) : nil
  end

  # ─── Scopes ───────────────────────────────────────────────────────────────────
  scope :active_webhooks, -> { where(is_active: true) }
  scope :for_event,       ->(event) { active_webhooks.where("? = ANY(events)", event) }

  # ─── Instance Methods ─────────────────────────────────────────────────────────
  def record_failure!(message = nil)
    new_count = failure_count.to_i + 1
    updates = { failure_count: new_count }
    updates[:is_active] = false if new_count >= MAX_FAILURES
    update!(updates)
  end

  def record_success!
    update!(failure_count: 0, last_triggered_at: Time.current)
  end

  private

  def validate_events_subset
    return if events.blank?
    invalid = events - SUPPORTED_EVENTS
    errors.add(:events, "contains unsupported events: #{invalid.join(', ')}") if invalid.any?
  end
end
