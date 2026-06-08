# Default host/port for URL generation outside of a request (jobs, models, mailers),
# e.g. building a blog's public URL (/@<username>/blog/<slug>) for the `blog.published`
# webhook payload. Public URLs are path-based on this single host (see config/routes.rb);
# no per-user subdomain is used, so a single-label host like the free *.onrender.com works.
Rails.application.config.after_initialize do
  options =
    if Rails.env.production?
      { host: ENV.fetch("APP_HOST", "parna.onrender.com"), protocol: "https" }
    else
      { host: "localhost", port: 3000 }
    end

  Rails.application.routes.default_url_options = options
end
