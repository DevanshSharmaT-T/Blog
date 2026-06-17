# frozen_string_literal: true

# Hard validation: rejects an attribute that contains banned/sensitive terms.
# Used for user-facing identifiers (name, username) where there is no review
# flow. Blog content uses a softer flag-for-review path instead.
#
#   validates :name, banned_words: true
class BannedWordsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    matches = ContentModeration.scan(value)
    return if matches.empty?

    record.errors.add(
      attribute,
      options[:message] || "contains a word that isn't allowed (#{matches.join(', ')})"
    )
  end
end
