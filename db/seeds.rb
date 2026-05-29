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
# 30 visual templates organised in five families. Each template's `slug` is the
# stable identifier — both the DB row and the CSS scope (`.tpl-<slug>`) live in
# [app/assets/stylesheets/templates.css](app/assets/stylesheets/templates.css).
templates = [
  # ── Editorial (10) ─────────────────────────────────────────
  { name: "Medium Classic",       slug: "medium-classic",       category: "editorial", is_premium: false,
    description: "Clean Medium-style reading view. Cream paper, serif body, drop cap on first paragraph.",
    layout_config: { font_family: "merriweather", palette: "warm-light", drop_cap: true,  hero_style: "narrow" } },
  { name: "NYT Style",            slug: "nyt-style",            category: "editorial", is_premium: false,
    description: "Newspaper-of-record aesthetic. Bold serif headline, all-caps byline, decorative dateline.",
    layout_config: { font_family: "merriweather", palette: "warm-light", drop_cap: false, hero_style: "narrow" } },
  { name: "Newspaper Justified",  slug: "newspaper-justified",  category: "editorial", is_premium: false,
    description: "Two-column justified body with hyphenation. Classic broadsheet rhythm.",
    layout_config: { font_family: "playfair",     palette: "warm-light", drop_cap: true,  hero_style: "narrow" } },
  { name: "Vogue Editorial",      slug: "vogue-editorial",      category: "editorial", is_premium: true,
    description: "Display serif title, oversized leading, all-caps subheadings, elegant capital ornaments.",
    layout_config: { font_family: "playfair",     palette: "pure-light", drop_cap: false, hero_style: "wide"   } },
  { name: "Monocle Modern",       slug: "monocle-modern",       category: "editorial", is_premium: false,
    description: "Light sans body with italic photo captions and tight tracking. Confident and current.",
    layout_config: { font_family: "inter",        palette: "warm-light", drop_cap: false, hero_style: "wide"   } },
  { name: "Kinfolk",              slug: "kinfolk",              category: "editorial", is_premium: true,
    description: "Warm cream paper, generous margins, restrained serif. Slow-reading vibe.",
    layout_config: { font_family: "merriweather", palette: "cream",      drop_cap: true,  hero_style: "narrow" } },
  { name: "Paris Review",         slug: "paris-review",         category: "editorial", is_premium: true,
    description: "Centre-aligned title with decorative double-rule dividers. Literary quarterly feel.",
    layout_config: { font_family: "merriweather", palette: "warm-light", drop_cap: true,  hero_style: "narrow" } },
  { name: "Atlantic",             slug: "atlantic",             category: "editorial", is_premium: false,
    description: "Modern editorial: refined serif, asymmetric meta strip, prominent deck.",
    layout_config: { font_family: "merriweather", palette: "pure-light", drop_cap: false, hero_style: "wide"   } },
  { name: "Atlantic Dark",        slug: "atlantic-dark",        category: "editorial", is_premium: true,
    description: "Dark take on the modern editorial. Bright serif headline against deep charcoal.",
    layout_config: { font_family: "merriweather", palette: "dark",       drop_cap: false, hero_style: "wide"   } },
  { name: "Literary Review",      slug: "literary-review",      category: "editorial", is_premium: false,
    description: "Narrow 36rem column, formal serif, footnote-style sidenotes. Built for long-form essays.",
    layout_config: { font_family: "merriweather", palette: "cream",      drop_cap: true,  hero_style: "narrow" } },

  # ── Minimal (8) ────────────────────────────────────────────
  { name: "Ghost Publication",    slug: "ghost-publication",    category: "minimal", is_premium: false,
    description: "Clone of the Ghost.org reading layout. Bold sans title, centred meta, generous space.",
    layout_config: { font_family: "inter",        palette: "pure-light", drop_cap: false, hero_style: "wide"   } },
  { name: "Paper Pure",           slug: "paper-pure",           category: "minimal", is_premium: false,
    description: "Pure white background, restrained serif, no decoration. Text first.",
    layout_config: { font_family: "merriweather", palette: "pure-light", drop_cap: false, hero_style: "narrow" } },
  { name: "Swiss Grid",           slug: "swiss-grid",           category: "minimal", is_premium: false,
    description: "Left-aligned strict grid, geometric sans-serif, rule-of-thirds spacing.",
    layout_config: { font_family: "inter",        palette: "pure-light", drop_cap: false, hero_style: "wide"   } },
  { name: "Notion Clean",         slug: "notion-clean",         category: "minimal", is_premium: false,
    description: "Friendly sans body, soft rounded surfaces, comfortable line-height.",
    layout_config: { font_family: "inter",        palette: "warm-light", drop_cap: false, hero_style: "narrow" } },
  { name: "Vellum",               slug: "vellum",               category: "minimal", is_premium: false,
    description: "Cream paper, soft hand-drawn underlines on links, italic deck.",
    layout_config: { font_family: "merriweather", palette: "cream",      drop_cap: true,  hero_style: "narrow" } },
  { name: "Linen",                slug: "linen",                category: "minimal", is_premium: false,
    description: "Warm beige background, serif throughout, woven texture suggestion.",
    layout_config: { font_family: "merriweather", palette: "linen",      drop_cap: false, hero_style: "narrow" } },
  { name: "Fog",                  slug: "fog",                  category: "minimal", is_premium: false,
    description: "Cool grey palette, soft contrast, calm and quiet.",
    layout_config: { font_family: "inter",        palette: "fog",        drop_cap: false, hero_style: "narrow" } },
  { name: "Dawn",                 slug: "dawn",                 category: "minimal", is_premium: false,
    description: "Soft peach-and-pink gradient hero, light body, warm and inviting.",
    layout_config: { font_family: "inter",        palette: "dawn",       drop_cap: false, hero_style: "wide"   } },

  # ── Bold / Display (6) ─────────────────────────────────────
  { name: "Brutalist",            slug: "brutalist",            category: "bold", is_premium: false,
    description: "Black background, white text, monospace headline. No border-radius, no apologies.",
    layout_config: { font_family: "mono",         palette: "brutalist",  drop_cap: false, hero_style: "narrow" } },
  { name: "Neobrutalist",         slug: "neobrutalist",         category: "bold", is_premium: false,
    description: "Bright accents, thick black borders, hard drop shadows. Playful and loud.",
    layout_config: { font_family: "inter",        palette: "neobrutal",  drop_cap: false, hero_style: "wide"   } },
  { name: "Manifesto",            slug: "manifesto",            category: "bold", is_premium: true,
    description: "Enormous headline, tight tracking, narrow body. Built to be read aloud.",
    layout_config: { font_family: "inter",        palette: "pure-light", drop_cap: false, hero_style: "narrow" } },
  { name: "Cyberpunk",            slug: "cyberpunk",            category: "bold", is_premium: true,
    description: "Deep dark surface with neon accent. Terminal vibe with editorial bones.",
    layout_config: { font_family: "mono",         palette: "cyberpunk",  drop_cap: false, hero_style: "narrow" } },
  { name: "Synthwave",            slug: "synthwave",            category: "bold", is_premium: true,
    description: "Retro 80s gradient hero, magenta and cyan accents, dark body.",
    layout_config: { font_family: "inter",        palette: "synthwave",  drop_cap: false, hero_style: "wide"   } },
  { name: "Zine",                 slug: "zine",                 category: "bold", is_premium: false,
    description: "Collage-feel page, hand-drawn elements, off-kilter alignment.",
    layout_config: { font_family: "mono",         palette: "warm-light", drop_cap: false, hero_style: "narrow" } },

  # ── Personal / Warm (3) ────────────────────────────────────
  { name: "Journal",              slug: "journal",              category: "warm", is_premium: true,
    description: "Handwritten title font, warm paper, personal-diary tone.",
    layout_config: { font_family: "cursive",      palette: "cream",      drop_cap: false, hero_style: "narrow" } },
  { name: "Letter",               slug: "letter",               category: "warm", is_premium: true,
    description: "Letterhead-style header, salutation, addressed-to-reader voice.",
    layout_config: { font_family: "merriweather", palette: "linen",      drop_cap: false, hero_style: "narrow" } },
  { name: "Garden",               slug: "garden",               category: "warm", is_premium: false,
    description: "Green and earth-tone palette, organic curves, plant-inspired ornaments.",
    layout_config: { font_family: "merriweather", palette: "garden",     drop_cap: true,  hero_style: "narrow" } },

  # ── Tech / Code (3) ────────────────────────────────────────
  { name: "Dev Blog",             slug: "dev-blog",             category: "tech", is_premium: false,
    description: "Code-block focused, monospace UI, dark by default. Tuned for developer essays.",
    layout_config: { font_family: "mono",         palette: "dark",       drop_cap: false, hero_style: "narrow" } },
  { name: "Documentation",        slug: "documentation",        category: "tech", is_premium: false,
    description: "Sidebar-TOC feel, sans body, technical and precise.",
    layout_config: { font_family: "inter",        palette: "pure-light", drop_cap: false, hero_style: "narrow" } },
  { name: "MDX Modern",           slug: "mdx-modern",           category: "tech", is_premium: true,
    description: "Vercel/Linear blog-inspired. Subtle gradient accents, geometric sans, dark.",
    layout_config: { font_family: "inter",        palette: "dark",       drop_cap: false, hero_style: "wide"   } }
]

# Retire the original three placeholder rows if they exist (they don't have CSS scopes).
Template.where(slug: %w[minimal magazine portfolio]).update_all(is_active: false)

templates.each do |attrs|
  t = Template.find_or_initialize_by(slug: attrs[:slug])
  t.assign_attributes(
    name:          attrs[:name],
    description:   attrs[:description],
    category:      attrs[:category],
    is_premium:    attrs[:is_premium],
    layout_config: attrs[:layout_config].transform_keys(&:to_s),
    is_active:     true,
    created_by_id: owner.id
  )
  t.save!
  puts "  ✅ Template: #{attrs[:name].ljust(22)} (#{attrs[:category]})"
end
puts "  📦 #{Template.active.count} templates active."

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
