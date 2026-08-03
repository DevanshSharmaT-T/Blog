# frozen_string_literal: true

# Calculates seo_score, readability_score, and promotion_score for a Blog.
# Scores range from 0–100, incremented in 20/25-point chunks per spec.
#
# Usage:
#   result = ScoringService.new(blog).call
#   # => { seo_score: 80, readability_score: 75, promotion_score: 100 }
class ScoringService
  def initialize(blog)
    @blog = blog
  end

  def call
    {
      seo_score:          calculate_seo_score,
      readability_score:  calculate_readability_score,
      promotion_score:    calculate_promotion_score
    }
  end

  private

  attr_reader :blog

  # ─── SEO Score (0–100) ────────────────────────────────────────────────────────
  # +20 seoTitle set and 30–60 chars
  # +20 seoDescription set and 120–160 chars
  # +20 slug is descriptive (no random chars, 10–60 chars)
  # +20 content contains at least one H2 heading
  # +20 coverImageUrl set and all images have altText
  def calculate_seo_score
    score = 0

    score += 20 if seo_title_valid?
    score += 20 if seo_description_valid?
    score += 20 if slug_descriptive?
    score += 20 if content_has_h2?
    score += 20 if cover_and_images_have_alt?

    score.clamp(0, 100)
  end

  def seo_title_valid?
    t = blog.seo_title
    t.present? && t.length.between?(30, 60)
  end

  def seo_description_valid?
    d = blog.seo_description
    d.present? && d.length.between?(120, 160)
  end

  def slug_descriptive?
    s = blog.slug.to_s
    return false unless s.length.between?(10, 60)
    # Must not look random: letters, numbers, hyphens; no UUID-style sequences
    s.match?(/\A[a-z][a-z0-9-]*[a-z0-9]\z/) && !s.match?(/[a-f0-9]{8}-[a-f0-9]{4}/)
  end

  def content_has_h2?
    parsed_content.css("h2").any?
  end

  def cover_and_images_have_alt?
    return false if blog.cover_image_url.blank?
    blog.images.all? { |img| img.alt_text.present? }
  end

  # ─── Readability Score (0–100) ────────────────────────────────────────────────
  # +25 avg sentence length < 20 words
  # +25 wordCount >= 300
  # +25 uses H2/H3 subheadings (at least 1 per 300 words)
  # +25 no paragraph exceeds 150 words
  def calculate_readability_score
    score = 0

    score += 25 if avg_sentence_length < 20
    score += 25 if blog.word_count.to_i >= 300
    score += 25 if sufficient_subheadings?
    score += 25 if no_long_paragraphs?

    score.clamp(0, 100)
  end

  def avg_sentence_length
    sentences = plain_text.split(/[.!?]+/).reject(&:empty?)
    return 0 if sentences.empty?
    total_words = sentences.sum { |s| s.split.size }
    total_words.to_f / sentences.size
  end

  def sufficient_subheadings?
    heading_count = parsed_content.css("h2, h3").size
    return false if heading_count.zero?
    words = blog.word_count.to_i
    required = (words / 300.0).floor
    heading_count >= [ required, 1 ].max
  end

  def no_long_paragraphs?
    parsed_content.css("p").all? { |p| p.text.split.size <= 150 }
  end

  # ─── Promotion Score (0–100) ──────────────────────────────────────────────────
  # +25 author has >= 2 connected social accounts
  # +25 blog has >= 2 topics assigned
  # +25 excerpt is set
  # +25 coverImageUrl is set
  def calculate_promotion_score
    score = 0

    score += 25 if blog.author.user_socials.count >= 2
    score += 25 if blog.topics.size >= 2
    score += 25 if blog.excerpt.present?
    score += 25 if blog.cover_image_url.present?

    score.clamp(0, 100)
  end

  # ─── Helpers ──────────────────────────────────────────────────────────────────
  def parsed_content
    @parsed_content ||= begin
      html = if blog.markdown_content_format?
               renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
               renderer.render(blog.content.to_s)
             else
               blog.content.to_s
             end
      Nokogiri::HTML::DocumentFragment.parse(html)
    end
  end

  def plain_text
    @plain_text ||= parsed_content.text
  end
end
