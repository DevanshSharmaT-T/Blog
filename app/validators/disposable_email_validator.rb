# frozen_string_literal: true

# Hard validation: rejects emails from known disposable/throwaway providers
# (yopmail, mailinator, …) so signups use a real, reachable address.
#
#   validates :email, disposable_email: true
class DisposableEmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    return unless ContentModeration.disposable_email?(value)

    record.errors.add(
      attribute,
      options[:message] || "must be from a non-disposable provider"
    )
  end
end
