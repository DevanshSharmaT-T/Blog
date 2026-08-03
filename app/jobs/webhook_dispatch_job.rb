# frozen_string_literal: true

class WebhookDispatchJob < ApplicationJob
  queue_as :default

  def perform(event_name, payload)
    WebhookDispatcher.dispatch(event_name, payload)
  end
end
