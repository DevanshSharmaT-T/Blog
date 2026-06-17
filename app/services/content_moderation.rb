# frozen_string_literal: true

# Single source of truth for content moderation. Backed by two curated, bundled
# lists (config/banned_words.yml, config/disposable_email_domains.txt) so checks
# are offline, deterministic, and identical everywhere they run:
#
#   * BannedWordsValidator / DisposableEmailValidator  → hard validation on User
#   * Blog#scan_for_banned_content                     → flag → admin review flow
#   * ModerationChecksController                       → live (debounced) feedback
#
# Lists are parsed once and memoized; restart the server to pick up edits.
module ContentModeration
  BANNED_WORDS_PATH = Rails.root.join("config", "banned_words.yml")
  DISPOSABLE_PATH   = Rails.root.join("config", "disposable_email_domains.txt")

  class << self
    # Returns the de-duplicated list of banned/sensitive terms found in `text`
    # (case-insensitive, matched on word boundaries). Empty array when clean.
    def scan(text)
      str = text.to_s
      return [] if str.blank?

      str.downcase.scan(banned_words_regex).flatten.compact.uniq
    end

    # True when `text` contains no banned/sensitive terms.
    def clean?(text)
      scan(text).empty?
    end

    # True when the email's domain is a known disposable/throwaway provider.
    def disposable_email?(email)
      domain = email.to_s.downcase.strip.split("@").last
      return false if domain.blank?

      disposable_domains.include?(domain)
    end

    # All configured terms, flattened across categories. Useful for tests.
    def banned_terms
      @banned_terms ||= banned_words.values.flatten.map { |w| w.to_s.downcase.strip }.reject(&:blank?).uniq
    end

    # Test/maintenance hook: drop memoized state so reloaded lists take effect.
    def reload!
      @banned_words = @banned_terms = @banned_words_regex = @disposable_domains = nil
    end

    private

    def banned_words
      @banned_words ||= (YAML.safe_load_file(BANNED_WORDS_PATH) || {})
    end

    # One combined, anchored regex over every term. Word boundaries (\b) prevent
    # false positives such as "ass" inside "class"; \p{L} lets boundaries work
    # for accented letters too. Phrases (e.g. "heil hitler") match verbatim.
    def banned_words_regex
      @banned_words_regex ||= begin
        alternation = banned_terms.map { |w| Regexp.escape(w) }.join("|")
        Regexp.new('(?<![\p{L}\p{N}])(?:' + alternation + ')(?![\p{L}\p{N}])', Regexp::IGNORECASE)
      end
    end

    def disposable_domains
      @disposable_domains ||= begin
        lines = File.exist?(DISPOSABLE_PATH) ? File.readlines(DISPOSABLE_PATH) : []
        lines.map { |l| l.strip.downcase }
             .reject { |l| l.blank? || l.start_with?("#") }
             .to_set
      end
    end
  end
end
