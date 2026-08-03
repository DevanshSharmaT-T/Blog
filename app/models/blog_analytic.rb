# frozen_string_literal: true

class BlogAnalytic < ApplicationRecord
  # ─── Associations ────────────────────────────────────────────────────────────
  belongs_to :blog

  # ─── Validations ─────────────────────────────────────────────────────────────
  validates :recorded_date, presence: true, uniqueness: { scope: :blog_id }
  validates :views,            numericality: { greater_than_or_equal_to: 0 }
  validates :unique_visitors,  numericality: { greater_than_or_equal_to: 0 }
  validates :bounce_rate,      numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :source,           presence: true

  # ─── Scopes ───────────────────────────────────────────────────────────────────
  scope :last_30_days,  -> { where(recorded_date: 30.days.ago.to_date..) }
  scope :last_7_days,   -> { where(recorded_date: 7.days.ago.to_date..) }
  scope :by_date,       -> { order(recorded_date: :asc) }
  scope :by_source,     ->(src) { where(source: src) }
end
