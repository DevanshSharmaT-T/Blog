# frozen_string_literal: true

# Delivery job for all outgoing mail. Retries on transient SMTP/network failures
# (e.g. Brevo connect/read timeouts) so a flaky mail server doesn't drop messages.
class MailerDeliveryJob < ActionMailer::MailDeliveryJob
  retry_on Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, IOError,
           wait: :polynomially_longer, attempts: 3
end
