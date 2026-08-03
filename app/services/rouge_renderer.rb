# frozen_string_literal: true

# Redcarpet renderer that highlights fenced code blocks with Rouge.
# Used by MarkdownHelper#render_blog_content.
class RougeRenderer < Redcarpet::Render::HTML
  def block_code(code, language)
    lexer = (language.present? && Rouge::Lexer.find(language)) || Rouge::Lexers::PlainText
    formatter = Rouge::Formatters::HTML.new
    %(<pre class="highlight"><code class="language-#{ERB::Util.html_escape(language)}">#{formatter.format(lexer.lex(code))}</code></pre>)
  end
end
