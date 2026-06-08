# Default host/port for URL generation outside of a request (jobs, models, mailers),
# e.g. building a blog's public subdomain URL for the `blog.published` webhook payload.
# In dev we use lvh.me (resolves to 127.0.0.1) so per-user subdomains work.
Rails.application.config.after_initialize do
  options =
    if Rails.env.production?
      { host: ENV.fetch("APP_HOST", "parna.onrender.com") }
    else
      # `*.localhost` resolves to 127.0.0.1 in modern browsers (no DNS needed),
      # so per-user subdomains work offline: <username>.localhost:3002.
      { host: "localhost", port: 3000 }
    end

  Rails.application.routes.default_url_options = options
end
