# frozen_string_literal: true

class IntegrationEvent < ApplicationRecord
  DIRECTIONS = %w[outbound inbound].freeze

  # ─── Associations ────────────────────────────────────────────────────────────
  belongs_to :integration, class_name: "ThirdPartyIntegration"
  belongs_to :blog, optional: true

  # ─── Validations ─────────────────────────────────────────────────────────────
  validates :event_type,  presence: true, length: { maximum: 80 }
  validates :direction,   presence: true, inclusion: { in: DIRECTIONS }

  # ─── Scopes ───────────────────────────────────────────────────────────────────
  scope :successful,  -> { where(success: true) }
  scope :failed,      -> { where(success: false) }
  scope :recent,      -> { order(created_at: :desc) }
  scope :last_50,     -> { recent.limit(50) }
  scope :outbound,    -> { where(direction: "outbound") }
  scope :inbound,     -> { where(direction: "inbound") }
end
