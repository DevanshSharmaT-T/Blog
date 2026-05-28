# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

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

  validates :website_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }

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

  def sync_email_verified_at
    self.email_verified_at = confirmed_at if confirmed_at_changed? && confirmed_at.present? && email_verified_at.nil?
  end
end
