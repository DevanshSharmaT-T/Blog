module SeoHelper
  DEFAULT_DESCRIPTION = "MyBlog — a modern blog platform. Read, write, and publish stories on technology, design, and ideas.".freeze
  DEFAULT_OG_IMAGE_PATH = "/og-default.png".freeze
  SITE_NAME = "MyBlog".freeze

  def page_title
    title = content_for?(:title) ? content_for(:title).to_s : nil
    title.present? ? "#{title} · #{SITE_NAME}" : "#{SITE_NAME} — Publish Your Story"
  end

  def meta_description
    raw = content_for?(:meta_description) ? content_for(:meta_description).to_s : nil
    (raw.presence || DEFAULT_DESCRIPTION).to_s.squish.truncate(160)
  end

  def canonical_url
    "#{request.protocol}#{request.host_with_port}#{request.path}"
  end

  def og_type
    @blog&.persisted? ? "article" : "website"
  end

  def og_image
    img =
      if @blog&.persisted? && @blog.cover_image_url.present?
        @blog.cover_image_url
      else
        DEFAULT_OG_IMAGE_PATH
      end
    absolute_url(img)
  end

  # Canonical public URL for a blog: /@<username>/blog/<slug> on the current host.
  #
  # ── PATH-BASED MODE (active) ──────────────────────────────────────────────────
  def public_blog_url_for(blog)
    public_blog_url(username: blog.author.username, slug: blog.slug)
  end
  #
  # ── SUBDOMAIN MODE (disabled) ── requires a wildcard domain; see config/routes.rb.
  # Built the host explicitly (not via `subdomain:`, which breaks on single-label
  # hosts like `localhost`) so links resolved regardless of the visitor's host.
  # def public_blog_url_for(blog)
  #   opts = Rails.application.routes.default_url_options
  #   public_blog_url(slug: blog.slug, host: "#{blog.author.username}.#{opts[:host]}", port: opts[:port])
  # end

  # Public author profile: /@<username> on the current host.
  #
  # ── PATH-BASED MODE (active) ──────────────────────────────────────────────────
  def public_profile_url_for(user)
    public_profile_url(username: user.username)
  end
  #
  # ── SUBDOMAIN MODE (disabled) ── requires a wildcard domain; see config/routes.rb.
  # def public_profile_url_for(user)
  #   opts = Rails.application.routes.default_url_options
  #   public_profile_url(host: "#{user.username}.#{opts[:host]}", port: opts[:port])
  # end

  # Make a possibly-relative path (e.g. a dev-local "/uploads/..") absolute so
  # crawlers and social cards always receive a full URL.
  def absolute_url(path_or_url)
    return path_or_url if path_or_url.to_s.match?(%r{\Ahttps?://})
    "#{request.base_url}#{path_or_url}"
  end

  def blog_json_ld(blog)
    data = {
      "@context"      => "https://schema.org",
      "@type"         => "BlogPosting",
      "headline"      => blog.title,
      "description"   => (blog.seo_description.presence || blog.excerpt.to_s.truncate(160)),
      "image"         => blog.cover_image_url.presence,
      "datePublished" => blog.published_at&.iso8601,
      "dateModified"  => blog.updated_at.iso8601,
      "author" => {
        "@type" => "Person",
        "name"  => blog.author.name
      },
      "publisher" => {
        "@type" => "Organization",
        "name"  => SITE_NAME
      },
      "mainEntityOfPage" => {
        "@type" => "WebPage",
        "@id"   => public_blog_url_for(blog)
      },
      "wordCount" => blog.word_count,
      "keywords"  => blog.topics.map(&:name).join(", ")
    }
    data.compact_blank.to_json.html_safe
  end
end
