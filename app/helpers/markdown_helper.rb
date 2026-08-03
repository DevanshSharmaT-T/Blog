module MarkdownHelper
  ALLOWED_TAGS = %w[
    h1 h2 h3 h4 h5 h6 p ul ol li a strong em b i u code pre blockquote
    img br hr table thead tbody tr th td span div figure figcaption sup sub
  ].freeze

  ALLOWED_ATTRS = %w[href src alt title class rel id loading].freeze

  def render_blog_content(blog)
    raw_html = if blog.html_content_format?
                 blog.content.to_s
               else
                 render_markdown(blog.content.to_s)
               end
    sanitize raw_html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRS
  end

  private

  def render_markdown(text)
    @markdown_renderer ||= Redcarpet::Markdown.new(
      RougeRenderer.new(hard_wrap: true, link_attributes: { rel: "noopener" }),
      autolink:            true,
      tables:              true,
      fenced_code_blocks:  true,
      strikethrough:       true,
      superscript:         true,
      no_intra_emphasis:   true,
      lax_spacing:         true
    )
    @markdown_renderer.render(text)
  end
end
