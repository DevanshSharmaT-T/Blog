# frozen_string_literal: true

# Dispatches webhook events to all active ApiWebhook subscribers.
#
# Usage:
#   WebhookDispatcher.dispatch("blog.published", { blog_id: "...", title: "..." })
class WebhookDispatcher
  TIMEOUT_SECS = 10

  def self.dispatch(event_name, payload)
    new(event_name, payload).dispatch
  end

  def initialize(event_name, payload)
    @event_name = event_name
    @payload    = payload
  end

  def dispatch
    webhooks = ApiWebhook.for_event(@event_name)
    webhooks.each { |webhook| deliver_to(webhook) }
  end

  private

  attr_reader :event_name, :payload

  def deliver_to(webhook)
    body       = build_body
    signature  = sign_payload(webhook.secret, body)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    begin
      response = HTTParty.post(
        webhook.target_url,
        body:    body,
        headers: {
          "Content-Type"      => "application/json",
          "X-Signature-256"   => "sha256=#{signature}",
          "X-Event-Type"      => event_name,
          "X-Webhook-Id"      => webhook.id,
          "User-Agent"        => "MyBlog-Webhook/1.0"
        },
        timeout: TIMEOUT_SECS
      )

      duration_ms = elapsed_ms(start_time)
      success = response.success?

      log_event(webhook, success: success, status_code: response.code, duration_ms: duration_ms)

      if success
        webhook.record_success!
      else
        webhook.record_failure!("HTTP #{response.code}: #{response.body.truncate(200)}")
      end
    rescue StandardError => e
      duration_ms = elapsed_ms(start_time)
      log_event(webhook, success: false, status_code: nil, duration_ms: duration_ms, error: e.message)
      webhook.record_failure!(e.message.truncate(255))
    end
  end

  def build_body
    {
      event:      event_name,
      payload:    payload,
      timestamp:  Time.current.iso8601
    }.to_json
  end

  def sign_payload(secret, body)
    OpenSSL::HMAC.hexdigest("SHA256", secret.to_s, body)
  end

  def elapsed_ms(start_time)
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round
  end

  def log_event(webhook, success:, status_code:, duration_ms:, error: nil)
    # Find or create a system-level integration for webhooks to link events
    integration = ThirdPartyIntegration.system_level.find_or_create_by!(
      provider:      "webhooks",
      provider_type: "notification"
    ) do |i|
      i.status = "active"
      i.label  = "System Webhooks"
    end

    IntegrationEvent.create!(
      integration:   integration,
      event_type:    event_name,
      direction:     "outbound",
      payload:       { webhook_id: webhook.id, target_url: webhook.target_url, body: payload },
      status_code:   status_code,
      success:       success,
      error_message: error,
      duration_ms:   duration_ms
    )
  end
end
