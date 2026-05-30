# frozen_string_literal: true

# Curated in-app icon library used for Topic icons (and reusable elsewhere).
#
# Each value is the *inner* markup of a Heroicons-style outline icon, designed
# for: viewBox="0 0 24 24", fill="none", stroke="currentColor". This matches the
# inline SVGs used throughout the app's views. The keys are the values stored in
# `topics.icon_name` — they MUST include every name used in db/seeds.rb.
module IconHelper
  ICONS = {
    # ── seeded names (keep these — existing topics reference them) ──────────────
    "cpu"            => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 7h10v10H7V7z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 10h4v4h-4z"/>),
    "palette"        => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4 9 9 0 019-9c4.97 0 9 3.582 9 8 0 2.21-1.79 4-4 4h-2a2 2 0 00-2 2 2 2 0 01-2 2H7z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7.5 13.5h.01M9.5 9.5h.01M13.5 9.5h.01M16 12h.01"/>),
    "briefcase"      => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 13.255A23.93 23.93 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v1m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>),
    "heart"          => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/>),
    "code"           => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"/>),
    "megaphone"      => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z"/>),
    "sparkles"       => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"/>),
    "lightning-bolt" => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/>),

    # ── neutral fallback (used when icon_name is blank/unknown) ─────────────────
    "tag"            => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5a1.99 1.99 0 011.414.586l7 7a2 2 0 010 2.828l-5 5a2 2 0 01-2.828 0l-7-7A1.99 1.99 0 014 7V4a1 1 0 011-1z"/>),

    # ── additional curated picks ────────────────────────────────────────────────
    "book"           => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>),
    "pen"            => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>),
    "camera"         => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z"/>),
    "music"          => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19V6l12-3v13M9 19c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zm12-3c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2z"/>),
    "globe"          => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"/>),
    "chart"          => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>),
    "rocket"         => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7M5 13l-2 6 6-2m4.5-8.5a2.5 2.5 0 113.536 3.536"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 6c2 2 4 5 4 8l-4 1-3-3 1-4c1.5-1 2-2 2-2z"/>),
    "flask"          => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 3h6M10 3v6.5L4.5 18A2 2 0 006.2 21h11.6a2 2 0 001.7-3L14 9.5V3"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7.5 14h9"/>),
    "cog"            => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>),
    "bell"           => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>),
    "bookmark"       => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"/>),
    "fire"           => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.879 16.121A3 3 0 1012.015 11L11 14H9c0 .768.293 1.536.879 2.121z"/>),
    "leaf"           => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 21c0-9 7-16 18-16 0 9-7 16-18 16z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 21c4-6 8-9 13-11"/>),
    "coffee"         => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 8h13v6a4 4 0 01-4 4H8a4 4 0 01-4-4V8z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9h2a2 2 0 012 2v0a2 2 0 01-2 2h-2M6 4v1m4-1v1"/>),
    "chat"           => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>),
    "users"          => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a4 4 0 00-3-3.87M9 20H4v-2a4 4 0 013-3.87m6-1.13a4 4 0 10-4-4m8 4a4 4 0 00-3-3.87"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7a4 4 0 11-8 0 4 4 0 018 0z"/>),
    "star"           => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.196-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.783-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z"/>),
    "lightbulb"      => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 18h6M10 21h4M12 3a6 6 0 00-3.6 10.8c.4.3.6.78.6 1.28V16h6v-.92c0-.5.2-.98.6-1.28A6 6 0 0012 3z"/>),
    "shield"         => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>),
    "map-pin"        => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>),
    "calendar"       => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>),
    "academic"       => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l9-5-9-5-9 5 9 5z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l6.16-3.422A12.083 12.083 0 0112 21.5a12.083 12.083 0 01-6.16-10.922L12 14z"/>),
    "gift"           => %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 8h14v3H5V8zm0 3v8a1 1 0 001 1h12a1 1 0 001-1v-8M12 8v13M12 8S9 8 8 6.5 8 4 9.5 4 12 8 12 8zm0 0s3 0 4-1.5S16 4 14.5 4 12 8 12 8z"/>),
  }.freeze

  # Render a single icon by name as an inline SVG. Falls back to a neutral "tag"
  # icon when the name is blank or not in the library.
  def topic_icon(name, **opts)
    classes = opts[:class] || "w-5 h-5"
    inner   = ICONS[name.to_s.presence] || ICONS["tag"]
    tag.svg(
      raw(inner),
      class: classes,
      fill: "none",
      stroke: "currentColor",
      viewBox: "0 0 24 24",
      "aria-hidden": "true"
    )
  end

  # All selectable icon names (used by the topic icon picker grid).
  def icon_library_names
    ICONS.keys
  end
end
