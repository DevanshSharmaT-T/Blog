# frozen_string_literal: true

# Bot / abuse protection (see plan: throttle + auto-ban abusive IPs on all public pages).
#
# Rack::Attack runs as middleware ahead of the controllers, so it guards every request —
# public pages, Devise forms, and APIs alike — without per-controller wiring.
#
# Bans/counters live in Rails.cache: Solid Cache in production (shared across Puma workers,
# survives restarts, auto-expires) and the in-memory store in development.
class Rack::Attack
  # Counters and bans share the app cache store. Solid Cache supports `increment` and
  # preserves the counter's expiry, which the time-window throttles rely on.
  Rack::Attack.cache.store = Rails.cache

  # Disabled in tests so the suite stays deterministic.
  Rack::Attack.enabled = !Rails.env.test?

  # How long a flagged IP stays fully blocked (403 on every request).
  BAN_FOR   = 24.hours
  FINDTIME  = 10.minutes

  # Resolve the *real* client IP. The app sits behind Cloudflare -> Render, so the visitor's
  # address is in CF-Connecting-IP; X-Forwarded-For's last public hop would otherwise be a
  # Cloudflare edge IP (172.69.x / 172.70.x ...), and banning that would lock out many users.
  def self.client_ip(req)
    req.get_header("HTTP_CF_CONNECTING_IP").presence ||
      req.get_header("action_dispatch.remote_ip")&.to_s ||
      req.ip
  end

  # Paths that obvious vulnerability scanners probe. Hitting any of these is never legitimate
  # for this app, so the IP is banned immediately (Tier 1).
  SCANNER_PATHS = Regexp.union(
    %r{\Awp-admin}i, %r{\Awp-login}i, %r{/wp-includes/}i, %r{xmlrpc\.php}i,
    %r{\.php\b}i, %r{/\.env\b}i, %r{/\.git\b}i, %r{/\.aws\b}i, %r{/\.ssh\b}i,
    %r{phpmyadmin}i, %r{/vendor/}i, %r{/cgi-bin/}i, %r{/wp-content/}i,
    %r{/\.well-known/(?!acme-challenge|security\.txt)}i
  )

  # Endpoints whose abuse should escalate to a full IP ban (Tier 2 brute force).
  AUTH_POST_PATHS = [ "/users/sign_in", "/users", "/users/confirmation", "/users/password" ].freeze

  ### Safelist — never throttled or blocked ####################################
  safelist("allow/health-and-assets") do |req|
    req.path == "/up" ||
      req.path.start_with?("/assets", "/rails/active_storage") ||
      req.path == "/robots.txt"
  end

  safelist("allow/localhost-in-dev") do |req|
    Rails.env.development? && [ "127.0.0.1", "::1" ].include?(client_ip(req))
  end

  ### Tier 1 — immediate 24h ban on scanner / exploit paths ####################
  # Fail2Ban bans the IP on the first hit (maxretry: 1) for BAN_FOR; every later request
  # from that IP then matches the ban check below and gets 403.
  blocklist("block/scanners") do |req|
    Rack::Attack::Fail2Ban.filter("scanner-#{client_ip(req)}", maxretry: 1, findtime: BAN_FOR, bantime: BAN_FOR) do
      SCANNER_PATHS.match?(req.path)
    end
  end

  ### Tier 2 — escalating 24h ban on brute force / floods ######################
  # Repeated auth POSTs from one IP (credential stuffing / signup spam) -> ban.
  blocklist("block/auth-brute-force") do |req|
    Rack::Attack::Allow2Ban.filter("auth-#{client_ip(req)}", maxretry: 20, findtime: FINDTIME, bantime: BAN_FOR) do
      req.post? && AUTH_POST_PATHS.include?(req.path)
    end
  end

  # Egregious flood far above any human browsing rate -> ban.
  blocklist("block/flood") do |req|
    Rack::Attack::Allow2Ban.filter("flood-#{client_ip(req)}", maxretry: 1000, findtime: 1.minute, bantime: BAN_FOR) do
      true # every request counts; only an IP doing >1000 req/min trips it
    end
  end

  ### Tier 3 — soft throttles (429, no ban) ####################################
  # General per-IP rate limit covering every public page.
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    client_ip(req) unless req.path.start_with?("/assets", "/rails/active_storage")
  end

  # Sensitive auth endpoints get tighter limits before Tier 2 ever escalates to a ban.
  throttle("login/ip", limit: 10, period: 1.minute) do |req|
    client_ip(req) if req.post? && req.path == "/users/sign_in"
  end

  throttle("signup/ip", limit: 10, period: 1.minute) do |req|
    client_ip(req) if req.post? && req.path == "/users"
  end

  throttle("confirmation/ip", limit: 5, period: 1.minute) do |req|
    client_ip(req) if req.post? && req.path == "/users/confirmation"
  end

  throttle("password/ip", limit: 5, period: 1.minute) do |req|
    client_ip(req) if req.post? && req.path == "/users/password"
  end

  # Debounced, per-keystroke signup validator — legitimately hit many times by real users,
  # so it gets a generous limit and never feeds the ban counters above.
  throttle("moderation/ip", limit: 60, period: 1.minute) do |req|
    client_ip(req) if req.post? && req.path == "/moderation/check"
  end

  ### Responses ################################################################
  self.throttled_responder = lambda do |req|
    match = req.env["rack.attack.match_data"] || {}
    retry_after = match[:period] || 60
    [ 429,
     { "Content-Type" => "text/plain", "Retry-After" => retry_after.to_s },
     [ "Too many requests. Please slow down and try again later.\n" ] ]
  end

  self.blocklisted_responder = lambda do |_req|
    [ 403, { "Content-Type" => "text/plain" }, [ "Forbidden\n" ] ]
  end
end

### Logging — surface blocked/throttled IPs in the Rails (Render) logs #########
ActiveSupport::Notifications.subscribe("rack.attack") do |_name, _start, _finish, _id, payload|
  req = payload[:request]
  match_type = req.env["rack.attack.match_type"]
  next unless %i[blocklist throttle].include?(match_type)

  Rails.logger.warn(
    "[Rack::Attack] #{match_type} #{req.env['rack.attack.matched']} " \
    "ip=#{Rack::Attack.client_ip(req)} #{req.request_method} #{req.fullpath}"
  )
end
