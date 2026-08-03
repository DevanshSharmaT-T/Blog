# frozen_string_literal: true

class UserSocial < ApplicationRecord
  # ─── Associations ────────────────────────────────────────────────────────────
  belongs_to :user
  belongs_to :social_platform

  # ─── Validations ─────────────────────────────────────────────────────────────
  validates :handle, presence: true, length: { maximum: 100 }
  validates :user_id, uniqueness: { scope: :social_platform_id, message: "already connected to this platform" }

  # ─── Encrypted Token Accessors ───────────────────────────────────────────────
  # Encrypted via EncryptionService — stored in *_ciphertext columns
  def access_token
    return nil if access_token_ciphertext.blank?
    EncryptionService.decrypt(access_token_ciphertext)
  rescue StandardError
    nil
  end

  def access_token=(plaintext)
    self.access_token_ciphertext = plaintext.present? ? EncryptionService.encrypt(plaintext) : nil
  end

  def refresh_token
    return nil if refresh_token_ciphertext.blank?
    EncryptionService.decrypt(refresh_token_ciphertext)
  rescue StandardError
    nil
  end

  def refresh_token=(plaintext)
    self.refresh_token_ciphertext = plaintext.present? ? EncryptionService.encrypt(plaintext) : nil
  end

  # ─── Scopes ───────────────────────────────────────────────────────────────────
  scope :public_profiles, -> { where(is_public: true) }
  scope :oauth_connected, -> { where.not(access_token_ciphertext: nil) }

  # ─── Instance Methods ─────────────────────────────────────────────────────────
  def token_expired?
    token_expires_at.present? && token_expires_at < Time.current
  end

  def platform_name
    social_platform&.name
  end
end
