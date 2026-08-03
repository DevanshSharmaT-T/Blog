# frozen_string_literal: true

class SocialPlatform < ApplicationRecord
  # ─── Associations ────────────────────────────────────────────────────────────
  has_many :user_socials, dependent: :destroy
  has_many :users, through: :user_socials

  # ─── Validations ─────────────────────────────────────────────────────────────
  validates :name, presence: true, uniqueness: true, length: { maximum: 60 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 40 },
                   format: { with: /\A[a-z0-9_-]+\z/, message: "must be lowercase alphanumeric with hyphens/underscores" }

  # ─── Scopes ───────────────────────────────────────────────────────────────────
  scope :active,         -> { where(is_active: true) }
  scope :oauth_enabled,  -> { where(supports_oauth: true) }

  def to_param
    slug
  end
end
