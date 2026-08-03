atom_feed language: "en-US" do |feed|
  feed.title "MyBlog — Latest Posts"
  feed.subtitle "Stories, tutorials, and ideas on technology, design, and creativity."
  feed.updated(@blogs.first&.updated_at || Time.current)

  @blogs.each do |blog|
    feed.entry(blog, url: public_blog_url_for(blog), published: blog.published_at, updated: blog.updated_at) do |entry|
      entry.title  blog.title
      entry.summary (blog.excerpt.presence || blog.title), type: "text"
      entry.content render_blog_content(blog), type: "html"
      entry.author do |author|
        author.name blog.author.name
      end
      blog.topics.each { |t| entry.category(term: t.slug, label: t.name) }
    end
  end
end
