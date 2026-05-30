# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  # Subdomains / paths that must never be used as a username.
  RESERVED_USERNAMES = %w[www app api admin blog assets mail root support help
                          settings dashboard new edit users topics templates].freeze

  # Preferred ordering for the handful of socials surfaced on public pages
  # (author card, profile). Platforms not in this list sort after these,
  # alphabetically by name.
  SOCIAL_PRIORITY = %w[instagram linkedin github twitter threads].freeze

  # ─── Enums ──────────────────────────────────────────────────────────────────
  enum :role, { owner: "owner", admin: "admin", user: "user", visitor: "visitor" },
       suffix: true

  # ─── Associations ────────────────────────────────────────────────────────────
  has_many :blogs,                   foreign_key: :author_id,     dependent: :nullify
  has_many :user_socials,            dependent: :destroy
  has_many :social_platforms,        through: :user_socials
  has_many :images,                  foreign_key: :uploaded_by_id, dependent: :nullify
  has_many :third_party_integrations, dependent: :destroy
  has_many :api_webhooks,            dependent: :destroy
  has_many :created_templates,       class_name: "Template",       foreign_key: :created_by_id, dependent: :nullify

  # ─── Validations ─────────────────────────────────────────────────────────────
  validates :name,  presence: true, length: { maximum: 120 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :role,  presence: true

  validates :username, presence: true, length: { in: 2..50 },
                       format: { with: /\A[a-z0-9][a-z0-9-]*\z/,
                                 message: "may only contain lowercase letters, numbers, and hyphens" },
                       uniqueness: { case_sensitive: false },
                       exclusion: { in: RESERVED_USERNAMES, message: "is reserved" }

  validates :website_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }

  # ─── Callbacks (username) ──────────────────────────────────────────────────
  before_validation :normalize_username
  before_validation :ensure_username

  # ─── Scopes ───────────────────────────────────────────────────────────────────
  scope :active,    -> { where(deleted_at: nil, is_active: true) }
  scope :not_deleted, -> { where(deleted_at: nil) }

  # ─── Callbacks ───────────────────────────────────────────────────────────────
  before_save :sync_email_verified_at

  # ─── Instance Methods ─────────────────────────────────────────────────────────
  def soft_delete!
    update!(deleted_at: Time.current, is_active: false)
  end

  def deleted?
    deleted_at.present?
  end

  def active_for_authentication?
    super && !deleted? && is_active?
  end

  # Public-facing socials, ordered by SOCIAL_PRIORITY then name. Only the
  # connections the author opted to show (is_public) are returned.
  def public_socials
    user_socials.includes(:social_platform).select(&:is_public).sort_by do |s|
      slug = s.social_platform&.slug.to_s
      [ SOCIAL_PRIORITY.index(slug) || SOCIAL_PRIORITY.length, s.social_platform&.name.to_s.downcase ]
    end
  end

  def inactive_message
    deleted? ? :deleted_account : super
  end

  # ─── Ransack ─────────────────────────────────────────────────────────────────
  def self.ransackable_attributes(_auth_object = nil)
    %w[name email role is_active created_at last_login_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[blogs user_socials]
  end

  private

  def normalize_username
    self.username = username.to_s.strip.downcase.presence
  end

  # Auto-derive a unique username from name/email when one isn't supplied.
  def ensure_username
    return if username.present?

    base = name.to_s.parameterize
    base = email.to_s.split("@").first.to_s.parameterize if base.blank?
    base = "user" if base.blank?
    base = base[0, 40]
    base = "#{base}-u" if RESERVED_USERNAMES.include?(base)

    candidate = base
    i = 1
    while RESERVED_USERNAMES.include?(candidate) ||
          self.class.where.not(id: id).exists?(username: candidate)
      i += 1
      candidate = "#{base}-#{i}"
    end
    self.username = candidate
  end

  def sync_email_verified_at
    self.email_verified_at = confirmed_at if confirmed_at_changed? && confirmed_at.present? && email_verified_at.nil?
  end
end
