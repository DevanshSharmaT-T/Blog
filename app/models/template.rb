# frozen_string_literal: true

class Template < ApplicationRecord
  # ─── Associations ────────────────────────────────────────────────────────────
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id, optional: true
  has_many   :blogs, dependent: :nullify

  # ─── Validations ─────────────────────────────────────────────────────────────
  validates :name, presence: true, length: { maximum: 120 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 80 },
                   format: { with: /\A[a-z0-9-]+\z/ }
  validates :layout_config, presence: true

  # ─── Callbacks ───────────────────────────────────────────────────────────────
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # ─── Scopes ───────────────────────────────────────────────────────────────────
  scope :active,  -> { where(is_active: true) }
  scope :free,    -> { where(is_premium: false) }
  scope :premium, -> { where(is_premium: true) }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
