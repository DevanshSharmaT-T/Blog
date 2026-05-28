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
    if @blog&.persisted? && @blog.cover_image_url.present?
      @blog.cover_image_url
    else
      "#{request.base_url}#{DEFAULT_OG_IMAGE_PATH}"
    end
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
        "@id"   => public_blog_url(slug: blog.slug)
      },
      "wordCount" => blog.word_count,
      "keywords"  => blog.topics.map(&:name).join(", ")
    }
    data.compact_blank.to_json.html_safe
  end
end
