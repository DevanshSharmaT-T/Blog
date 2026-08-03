# frozen_string_literal: true

class Image < ApplicationRecord
  # ─── Associations ────────────────────────────────────────────────────────────
  belongs_to :blog
  belongs_to :uploader, class_name: "User", foreign_key: :uploaded_by_id

  # ─── Validations ─────────────────────────────────────────────────────────────
  validates :url, presence: true
  validates :mime_type, inclusion: { in: %w[image/jpeg image/png image/gif image/webp image/svg+xml], allow_blank: true }

  # ─── Scopes ───────────────────────────────────────────────────────────────────
  scope :ordered, -> { order(display_order: :asc, created_at: :asc) }
end
