# frozen_string_literal: true

class Topic < ApplicationRecord
  # ─── Associations ────────────────────────────────────────────────────────────
  belongs_to :parent, class_name: "Topic", optional: true
  has_many   :sub_topics, class_name: "Topic", foreign_key: :parent_id, dependent: :nullify
  has_many   :blog_topics, dependent: :destroy
  has_many   :blogs, through: :blog_topics

  # ─── Validations ─────────────────────────────────────────────────────────────
  validates :name, presence: true, uniqueness: true, length: { maximum: 80 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 80 },
                   format: { with: /\A[a-z0-9-]+\z/, message: "must be lowercase with hyphens only" }
  validates :color_hex, format: { with: /\A#[0-9A-Fa-f]{6}\z/, allow_blank: true }
  validate  :no_circular_parent

  # ─── Callbacks ───────────────────────────────────────────────────────────────
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # ─── Scopes ───────────────────────────────────────────────────────────────────
  scope :active,     -> { where(is_active: true) }
  scope :root_level, -> { where(parent_id: nil) }
  scope :by_name,    -> { order(:name) }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end

  def no_circular_parent
    return unless parent_id.present? && parent_id == id
    errors.add(:parent_id, "cannot be the topic itself")
  end
end
