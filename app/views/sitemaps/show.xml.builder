xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
  xml.url do
    xml.loc        root_url
    xml.changefreq "daily"
    xml.priority   1.0
  end
  xml.url do
    xml.loc        blog_archive_url
    xml.changefreq "daily"
    xml.priority   0.9
  end
  xml.url do
    xml.loc        topics_url
    xml.changefreq "weekly"
    xml.priority   0.7
  end

  @blogs.each do |blog|
    xml.url do
      xml.loc        public_blog_url(slug: blog.slug)
      xml.lastmod    blog.updated_at.iso8601
      xml.changefreq "weekly"
      xml.priority   0.8
    end
  end

  @topics.each do |topic|
    xml.url do
      xml.loc        topic_url(topic)
      xml.changefreq "weekly"
      xml.priority   0.6
    end
  end
end
