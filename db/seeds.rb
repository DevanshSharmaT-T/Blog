# frozen_string_literal: true

puts "🌱 Seeding database..."

# ─── 1. Owner user ────────────────────────────────────────────────────────────
owner = User.find_or_initialize_by(email: ENV.fetch("OWNER_EMAIL", "owner@myblog.dev"))
owner.assign_attributes(
  name:     ENV.fetch("OWNER_NAME", "Blog Owner"),
  role:     :owner,
  password: ENV.fetch("OWNER_PASSWORD", "Password1!"),
  password_confirmation: ENV.fetch("OWNER_PASSWORD", "Password1!"),
  is_active: true,
  confirmed_at: Time.current,
  email_verified_at: Time.current
)
owner.save!
puts "  ✅ Owner: #{owner.email}"

# ─── 2. Sample users ──────────────────────────────────────────────────────────
[
  { name: "Alice Admin", email: "admin@myblog.dev", role: :admin },
  { name: "Bob Writer",  email: "writer@myblog.dev", role: :user }
].each do |attrs|
  u = User.find_or_initialize_by(email: attrs[:email])
  u.assign_attributes(
    name: attrs[:name], role: attrs[:role],
    password: "Password1!", password_confirmation: "Password1!",
    is_active: true, confirmed_at: Time.current, email_verified_at: Time.current
  )
  u.save!
  puts "  ✅ User: #{u.email} (#{u.role})"
end

# ─── 3. Social platforms ──────────────────────────────────────────────────────
platforms = [
  { name: "Twitter / X",    slug: "twitter",    base_url: "https://twitter.com/",    supports_oauth: true },
  { name: "Instagram",      slug: "instagram",  base_url: "https://instagram.com/",  supports_oauth: true },
  { name: "LinkedIn",       slug: "linkedin",   base_url: "https://linkedin.com/in/", supports_oauth: true },
  { name: "Facebook",       slug: "facebook",   base_url: "https://facebook.com/",   supports_oauth: true },
  { name: "YouTube",        slug: "youtube",    base_url: "https://youtube.com/@",    supports_oauth: true },
  { name: "TikTok",         slug: "tiktok",     base_url: "https://tiktok.com/@",     supports_oauth: false },
  { name: "Pinterest",      slug: "pinterest",  base_url: "https://pinterest.com/",  supports_oauth: false },
  { name: "Threads",        slug: "threads",    base_url: "https://threads.net/@",    supports_oauth: false },
  { name: "Mastodon",       slug: "mastodon",   base_url: "https://mastodon.social/@", supports_oauth: false },
  { name: "Substack",       slug: "substack",   base_url: "https://substack.com/@",   supports_oauth: false },
  { name: "Medium",         slug: "medium",     base_url: "https://medium.com/@",     supports_oauth: false },
  { name: "GitHub",         slug: "github",     base_url: "https://github.com/",      supports_oauth: true },
  { name: "Behance",        slug: "behance",    base_url: "https://behance.net/",      supports_oauth: false },
  { name: "Dribbble",       slug: "dribbble",   base_url: "https://dribbble.com/",    supports_oauth: false }
]

platforms.each do |attrs|
  SocialPlatform.find_or_create_by!(slug: attrs[:slug]) do |p|
    p.name           = attrs[:name]
    p.base_url       = attrs[:base_url]
    p.supports_oauth = attrs[:supports_oauth]
    p.is_active      = true
  end
  puts "  ✅ Platform: #{attrs[:name]}"
end

# ─── 4. Topics ────────────────────────────────────────────────────────────────
topics = [
  { name: "Technology",    slug: "technology",    color_hex: "#6366f1", icon_name: "cpu" },
  { name: "Design",        slug: "design",        color_hex: "#8b5cf6", icon_name: "palette" },
  { name: "Business",      slug: "business",      color_hex: "#0ea5e9", icon_name: "briefcase" },
  { name: "Lifestyle",     slug: "lifestyle",     color_hex: "#10b981", icon_name: "heart" },
  { name: "Programming",   slug: "programming",   color_hex: "#f59e0b", icon_name: "code" },
  { name: "Marketing",     slug: "marketing",     color_hex: "#ef4444", icon_name: "megaphone" },
  { name: "AI & ML",       slug: "ai-ml",         color_hex: "#a855f7", icon_name: "sparkles" },
  { name: "Productivity",  slug: "productivity",  color_hex: "#14b8a6", icon_name: "lightning-bolt" }
]

topics.each do |attrs|
  Topic.find_or_create_by!(slug: attrs[:slug]) do |t|
    t.name      = attrs[:name]
    t.color_hex = attrs[:color_hex]
    t.icon_name = attrs[:icon_name]
    t.is_active = true
  end
  puts "  ✅ Topic: #{attrs[:name]}"
end

# ─── 5. Templates ─────────────────────────────────────────────────────────────
templates = [
  {
    name: "Minimal",
    slug: "minimal",
    description: "Clean, distraction-free reading experience with generous whitespace.",
    category: "minimal",
    is_premium: false,
    layout_config: {
      "font" => "merriweather",
      "layout" => "single-column",
      "max_width" => "720px",
      "show_sidebar" => false,
      "color_scheme" => "dark"
    }
  },
  {
    name: "Magazine",
    slug: "magazine",
    description: "Rich magazine-style layout with sidebar, featured images, and category strips.",
    category: "magazine",
    is_premium: false,
    layout_config: {
      "font" => "inter",
      "layout" => "two-column",
      "max_width" => "1200px",
      "show_sidebar" => true,
      "color_scheme" => "dark"
    }
  },
  {
    name: "Portfolio",
    slug: "portfolio",
    description: "Showcase your work with a visual-first layout perfect for creatives.",
    category: "portfolio",
    is_premium: true,
    layout_config: {
      "font" => "inter",
      "layout" => "full-width",
      "max_width" => "1440px",
      "show_sidebar" => false,
      "color_scheme" => "dark",
      "hero_style" => "cover"
    }
  }
]

templates.each do |attrs|
  Template.find_or_create_by!(slug: attrs[:slug]) do |t|
    t.name          = attrs[:name]
    t.description   = attrs[:description]
    t.category      = attrs[:category]
    t.is_premium    = attrs[:is_premium]
    t.layout_config = attrs[:layout_config]
    t.is_active     = true
    t.created_by_id = owner.id
  end
  puts "  ✅ Template: #{attrs[:name]}"
end

# ─── 6. Sample blog post ──────────────────────────────────────────────────────
writer = User.find_by!(email: "writer@myblog.dev")
unless Blog.exists?(slug: "getting-started-with-myblog")
  blog = Blog.create!(
    author: writer,
    title:   "Getting Started with MyBlog",
    slug:    "getting-started-with-myblog",
    excerpt: "A comprehensive guide to setting up your blog platform and publishing your first post.",
    content: <<~MD,
      ## Introduction

      Welcome to **MyBlog** — your production-ready blog platform built on Rails 8.

      This guide will walk you through everything you need to know to start publishing great content.

      ## Setting Up Your Profile

      Start by connecting your social accounts in **Settings → Connected Accounts**. Having at least two connected platforms will boost your promotion score by 25 points.

      ## Creating Your First Blog

      Click **New Blog** in the sidebar and follow the four-step wizard:

      1. **Topics** — Choose relevant topics for your post
      2. **Content** — Write in Markdown with our built-in editor
      3. **Template** — Pick a visual layout
      4. **Review** — Check your SEO and readability scores before publishing

      ## Understanding Your Scores

      Every blog gets three scores:

      - **SEO Score** — How well-optimized your post is for search engines
      - **Readability Score** — How easy your content is to read
      - **Promotion Score** — How effectively you can promote this post

      Aim for 80+ on all three for the best results!

      ## Next Steps

      - Connect your analytics provider in the Integrations page
      - Set up webhooks to notify your team when posts are published
      - Explore templates to find the perfect look for your content
    MD
    content_format: :markdown,
    status:         :published,
    published_at:   Time.current,
    word_count:     200,
    reading_time_mins: 2,
    seo_title:      "Getting Started with MyBlog — Your Blog Platform",
    seo_description: "Learn how to set up your MyBlog platform, create compelling blog posts, and optimize your content for SEO and promotion.",
    featured:       true,
    allow_comments: true
  )

  tech_topic = Topic.find_by!(slug: "technology")
  blog.blog_topics.create!(topic: tech_topic)
  puts "  ✅ Sample blog: #{blog.title}"
end

puts "\n✨ Seeding complete!"
puts "   Owner login: #{ENV.fetch('OWNER_EMAIL', 'owner@myblog.dev')} / #{ENV.fetch('OWNER_PASSWORD', 'Password1!')}"
