# frozen_string_literal: true

# AES-256-GCM encryption service.
# Requires ENV["ENCRYPTION_KEY"] to be a 64-char hex string (32 bytes).
#
# Usage:
#   ciphertext = EncryptionService.encrypt("my secret")
#   plaintext  = EncryptionService.decrypt(ciphertext)
module EncryptionService
  ALGORITHM = "aes-256-gcm"
  AUTH_TAG_LENGTH = 16

  class EncryptionError < StandardError; end
  class DecryptionError < StandardError; end

  def self.key
    @key ||= begin
      hex = ENV.fetch("ENCRYPTION_KEY") { raise EncryptionError, "ENCRYPTION_KEY env var is not set" }
      [ hex ].pack("H*").tap do |k|
        raise EncryptionError, "ENCRYPTION_KEY must be 32 bytes (64 hex chars)" unless k.bytesize == 32
      end
    end
  end

  # Returns base64-encoded string: base64(iv + auth_tag + ciphertext)
  def self.encrypt(plaintext)
    raise EncryptionError, "plaintext cannot be nil" if plaintext.nil?

    cipher = OpenSSL::Cipher.new(ALGORITHM)
    cipher.encrypt
    iv = cipher.random_iv
    cipher.key = key
    cipher.auth_data = ""

    ciphertext = cipher.update(plaintext.to_s) + cipher.final
    auth_tag   = cipher.auth_tag(AUTH_TAG_LENGTH)

    Base64.strict_encode64(iv + auth_tag + ciphertext)
  end

  # Decrypts a base64-encoded string produced by #encrypt
  def self.decrypt(ciphertext_b64)
    raise DecryptionError, "ciphertext cannot be nil" if ciphertext_b64.nil?

    raw        = Base64.strict_decode64(ciphertext_b64)
    iv         = raw.byteslice(0, 12)
    auth_tag   = raw.byteslice(12, AUTH_TAG_LENGTH)
    ciphertext = raw.byteslice(12 + AUTH_TAG_LENGTH, raw.bytesize)

    cipher = OpenSSL::Cipher.new(ALGORITHM)
    cipher.decrypt
    cipher.key      = key
    cipher.iv       = iv
    cipher.auth_tag = auth_tag
    cipher.auth_data = ""

    cipher.update(ciphertext) + cipher.final
  rescue OpenSSL::Cipher::CipherError => e
    raise DecryptionError, "Decryption failed: #{e.message}"
  rescue ArgumentError => e
    raise DecryptionError, "Invalid ciphertext encoding: #{e.message}"
  end
end
