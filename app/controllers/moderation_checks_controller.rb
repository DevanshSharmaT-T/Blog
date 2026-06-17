# frozen_string_literal: true

# Backs the interactive (debounced) field validation in the browser. The
# field_validator Stimulus controller POSTs a single field value here and gets
# back a small JSON verdict so the UI can warn before the form is submitted.
# Server-side validators/callbacks remain the real enforcement — this endpoint
# is purely for fast feedback, so it never persists anything.
#
# Public on purpose: the signup form must be able to check the email/name of a
# not-yet-authenticated visitor.
class ModerationChecksController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  # POST /moderation/check  { kind: "text"|"email"|"flaggable", value: "..." }
  def create
    kind  = params[:kind].to_s
    value = params[:value].to_s

    render json: verdict_for(kind, value)
  end

  private

  def verdict_for(kind, value)
    case kind
    when "email"
      if ContentModeration.disposable_email?(value)
        { ok: false, kind: kind, severity: "error",
          message: "Disposable email addresses aren't allowed. Please use a permanent address." }
      else
        { ok: true, kind: kind }
      end
    when "flaggable" # blog title/excerpt/content — soft warning, not a block
      matches = ContentModeration.scan(value)
      if matches.any?
        { ok: false, kind: kind, severity: "warning", matches: matches,
          message: "Heads up: this contains flagged words (#{matches.join(', ')}). " \
                   "You can keep writing, but the post will need admin review before it can be published." }
      else
        { ok: true, kind: kind }
      end
    else # "text" — username / display name, hard block
      matches = ContentModeration.scan(value)
      if matches.any?
        { ok: false, kind: "text", severity: "error", matches: matches,
          message: "This contains a word that isn't allowed (#{matches.join(', ')})." }
      else
        { ok: true, kind: "text" }
      end
    end
  end
end
