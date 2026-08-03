# frozen_string_literal: true

class ThirdPartyIntegration < ApplicationRecord
  VALID_PROVIDER_TYPES = %w[analytics email social ai storage seo cms payment notification custom].freeze
  VALID_STATUSES = %w[active inactive error revoked].freeze

  # ─── Associations ────────────────────────────────────────────────────────────
  belongs_to :user, optional: true  # null = system-level
  has_many   :integration_events, foreign_key: :integration_id, dependent: :destroy

  # ─── Validations ─────────────────────────────────────────────────────────────
  validates :provider,      presence: true, length: { maximum: 60 }
  validates :provider_type, presence: true
  validates :status,        presence: true

  # ─── Encrypted Credentials Accessor ──────────────────────────────────────────
  def credentials
    return {} if credentials_ciphertext.blank?
    JSON.parse(EncryptionService.decrypt(credentials_ciphertext))
  rescue StandardError
    {}
  end

  def credentials=(hash)
    self.credentials_ciphertext = hash.present? ? EncryptionService.encrypt(hash.to_json) : nil
  end

  # ─── Scopes ───────────────────────────────────────────────────────────────────
  scope :active,          -> { where(status: "active") }
  scope :by_type,         ->(type) { where(provider_type: type) }
  scope :for_user,        ->(user) { where(user: user) }
  scope :system_level,    -> { where(user_id: nil) }

  # ─── Instance Methods ─────────────────────────────────────────────────────────
  def active?
    status == "active"
  end

  def mark_error!(message)
    update!(status: "error", error_message: message)
  end

  def mark_active!
    update!(status: "active", error_message: nil, last_tested_at: Time.current)
  end
end
