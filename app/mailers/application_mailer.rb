class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.dig(:brevo, :SMTP_SENDER) ||
                ENV.fetch("SMTP_SENDER", "sharmadevansh795@gmail.com")
  layout "mailer"
end
