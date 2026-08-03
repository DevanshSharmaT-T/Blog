# Blog Application — Database Schema

> **Version:** 1.0.0  
> **Stack:** PostgreSQL (primary) · Designed for third-party API integration  
> **Conventions:** UUIDs for all primary keys · `snake_case` throughout · Soft deletes via `deleted_at` where noted · All timestamps in UTC

---

## Table of Contents

1. [users](#1-users)
2. [user_socials](#2-user_socials)
3. [social_platforms](#3-social_platforms)
4. [topics](#4-topics)
5. [templates](#5-templates)
6. [blogs](#6-blogs)
7. [blog_topics](#7-blog_topics)
8. [images](#8-images)
9. [blog_analytics](#9-blog_analytics)
10. [third_party_integrations](#10-third_party_integrations)
11. [integration_events](#11-integration_events)
12. [api_webhooks](#12-api_webhooks)
13. [Relationships Summary](#relationships-summary)
14. [Enums Reference](#enums-reference)
15. [Integration Design Notes](#integration-design-notes)

---

## 1. `users`

Core account table. Supports all four role tiers.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | PK, default `gen_random_uuid()` | Primary key |
| `name` | `VARCHAR(120)` | NOT NULL | Display name |
| `email` | `VARCHAR(255)` | NOT NULL, UNIQUE | Login email |
| `password_hash` | `TEXT` | NOT NULL | Bcrypt / Argon2 hash |
| `role` | `user_role` (enum) | NOT NULL, default `'user'` | Access tier |
| `avatar_url` | `TEXT` | nullable | Profile photo URL |
| `bio` | `TEXT` | nullable | Short biography |
| `website_url` | `TEXT` | nullable | Personal/brand website |
| `is_active` | `BOOLEAN` | NOT NULL, default `true` | Account enabled flag |
| `email_verified_at` | `TIMESTAMPTZ` | nullable | Email confirmation timestamp |
| `last_login_at` | `TIMESTAMPTZ` | nullable | Last successful login |
| `deleted_at` | `TIMESTAMPTZ` | nullable | Soft delete timestamp |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | Row creation time |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | Last modification time |

**Indexes:** `email` (unique), `role`, `deleted_at`

---

## 2. `user_socials`

Stores all social media handles and external profile links for a user. One row per platform per user.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | PK | Primary key |
| `user_id` | `UUID` | FK → `users.id`, NOT NULL | Owning user |
| `platform_id` | `UUID` | FK → `social_platforms.id`, NOT NULL | Which platform |
| `handle` | `VARCHAR(100)` | NOT NULL | Username / handle on that platform (e.g. `@johndoe`) |
| `profile_url` | `TEXT` | nullable | Full URL to the profile page |
| `follower_count` | `INTEGER` | nullable | Cached follower count (synced via API) |
| `is_verified` | `BOOLEAN` | NOT NULL, default `false` | Verified/blue-tick on that platform |
| `is_public` | `BOOLEAN` | NOT NULL, default `true` | Show on public profile |
| `access_token` | `TEXT` | nullable, encrypted | OAuth access token (for platforms that allow posting) |
| `refresh_token` | `TEXT` | nullable, encrypted | OAuth refresh token |
| `token_expires_at` | `TIMESTAMPTZ` | nullable | Token expiry time |
| `last_synced_at` | `TIMESTAMPTZ` | nullable | Last time follower data was pulled |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | — |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | — |

**Unique constraint:** `(user_id, platform_id)`  
**Indexes:** `user_id`, `platform_id`

> **Security note:** `access_token` and `refresh_token` must be stored encrypted at rest (e.g. using `pgcrypto` or application-level AES-256). Never log these fields.

---

## 3. `social_platforms`

Reference table for all supported social/content platforms.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | PK | Primary key |
| `name` | `VARCHAR(60)` | NOT NULL, UNIQUE | Human-readable name (e.g. `Twitter / X`) |
| `slug` | `VARCHAR(40)` | NOT NULL, UNIQUE | Machine key (e.g. `twitter`, `instagram`, `linkedin`) |
| `base_url` | `TEXT` | nullable | Base profile URL template (e.g. `https://twitter.com/`) |
| `icon_url` | `TEXT` | nullable | Platform logo/icon |
| `supports_oauth` | `BOOLEAN` | NOT NULL, default `false` | Can we connect via OAuth |
| `api_version` | `VARCHAR(20)` | nullable | Current API version in use |
| `is_active` | `BOOLEAN` | NOT NULL, default `true` | Show in UI for users to connect |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | — |

**Seed data (suggested slugs):** `twitter`, `instagram`, `linkedin`, `facebook`, `youtube`, `tiktok`, `pinterest`, `threads`, `mastodon`, `substack`, `medium`, `github`, `behance`, `dribbble`

---

## 4. `topics`

Reusable taxonomy for categorising blog posts.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | PK | Primary key |
| `name` | `VARCHAR(80)` | NOT NULL, UNIQUE | Display name |
| `slug` | `VARCHAR(80)` | NOT NULL, UNIQUE | URL-safe identifier |
| `description` | `TEXT` | nullable | Short topic summary |
| `color_hex` | `CHAR(7)` | nullable | UI accent colour (e.g. `#FF6B35`) |
| `icon_name` | `VARCHAR(50)` | nullable | Icon identifier |
| `parent_id` | `UUID` | FK → `topics.id`, nullable | Enables sub-topics / hierarchy |
| `post_count` | `INTEGER` | NOT NULL, default `0` | Denormalised count (updated by trigger) |
| `is_active` | `BOOLEAN` | NOT NULL, default `true` | Visible to users |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | — |

**Indexes:** `slug` (unique), `parent_id`

---

## 5. `templates`

Visual layout templates users can apply to their blogs.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | PK | Primary key |
| `name` | `VARCHAR(120)` | NOT NULL | Template display name |
| `slug` | `VARCHAR(80)` | NOT NULL, UNIQUE | Machine identifier |
| `description` | `TEXT` | nullable | What this template looks like / is best for |
| `thumbnail_url` | `TEXT` | nullable | Preview image shown in picker |
| `preview_url` | `TEXT` | nullable | Live preview URL |
| `layout_config` | `JSONB` | NOT NULL, default `'{}'` | Full layout definition (component tree, colours, fonts, etc.) |
| `category` | `VARCHAR(50)` | nullable | e.g. `minimal`, `magazine`, `portfolio` |
| `is_premium` | `BOOLEAN` | NOT NULL, default `false` | Requires paid plan |
| `is_active` | `BOOLEAN` | NOT NULL, default `true` | Available in the picker |
| `created_by` | `UUID` | FK → `users.id`, nullable | Who built this template |
| `usage_count` | `INTEGER` | NOT NULL, default `0` | Denormalised; updated by trigger |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | — |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | — |

---

## 6. `blogs`

The core content table.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | PK | Primary key |
| `author_id` | `UUID` | FK → `users.id`, NOT NULL | Owning author |
| `template_id` | `UUID` | FK → `templates.id`, nullable | Applied layout template |
| `title` | `VARCHAR(255)` | NOT NULL | Blog post title |
| `slug` | `VARCHAR(255)` | NOT NULL, UNIQUE | URL-safe post identifier |
| `excerpt` | `TEXT` | nullable | Short teaser / meta description |
| `content` | `TEXT` | NOT NULL | Raw body content (Markdown or HTML) |
| `content_format` | `VARCHAR(20)` | NOT NULL, default `'markdown'` | `markdown` or `html` |
| `cover_image_url` | `TEXT` | nullable | Hero/cover image |
| `status` | `blog_status` (enum) | NOT NULL, default `'draft'` | Lifecycle stage |
| `seo_title` | `VARCHAR(70)` | nullable | Override for `<title>` tag |
| `seo_description` | `VARCHAR(160)` | nullable | Meta description |
| `seo_score` | `SMALLINT` | nullable | 0–100 search optimisation score |
| `readability_score` | `SMALLINT` | nullable | 0–100 readability score |
| `promotion_score` | `SMALLINT` | nullable | 0–100 promotion ease score |
| `word_count` | `INTEGER` | nullable | Auto-calculated |
| `reading_time_mins` | `SMALLINT` | nullable | Estimated reading time |
| `featured` | `BOOLEAN` | NOT NULL, default `false` | Pinned / featured flag |
| `allow_comments` | `BOOLEAN` | NOT NULL, default `true` | Comment toggle |
| `published_at` | `TIMESTAMPTZ` | nullable | When first published |
| `scheduled_at` | `TIMESTAMPTZ` | nullable | Future publish date |
| `deleted_at` | `TIMESTAMPTZ` | nullable | Soft delete |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | — |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | — |

**Indexes:** `author_id`, `status`, `slug` (unique), `published_at`, `deleted_at`, `featured`

---

## 7. `blog_topics`

Many-to-many join between blogs and topics. A blog can have multiple topics.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `blog_id` | `UUID` | FK → `blogs.id`, NOT NULL | — |
| `topic_id` | `UUID` | FK → `topics.id`, NOT NULL | — |
| `assigned_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | When tag was applied |

**Primary key:** `(blog_id, topic_id)`

---

## 8. `images`

Images uploaded as part of a blog post's body.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | PK | Primary key |
| `blog_id` | `UUID` | FK → `blogs.id`, NOT NULL | Owning blog post |
| `uploaded_by` | `UUID` | FK → `users.id`, NOT NULL | Uploader |
| `url` | `TEXT` | NOT NULL | Storage URL (CDN or S3) |
| `storage_key` | `TEXT` | nullable | Internal storage path/key |
| `mime_type` | `VARCHAR(50)` | nullable | e.g. `image/jpeg` |
| `file_size_bytes` | `INTEGER` | nullable | File size |
| `width_px` | `INTEGER` | nullable | Image width |
| `height_px` | `INTEGER` | nullable | Image height |
| `alt_text` | `TEXT` | nullable | Accessibility alt text |
| `caption` | `TEXT` | nullable | Visible caption under image |
| `display_order` | `SMALLINT` | NOT NULL, default `0` | Ordering within the post |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | — |

**Indexes:** `blog_id`, `uploaded_by`

---

## 9. `blog_analytics`

Daily performance snapshot per blog. Feeds the owner dashboard.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | PK | Primary key |
| `blog_id` | `UUID` | FK → `blogs.id`, NOT NULL | Tracked post |
| `recorded_date` | `DATE` | NOT NULL | Snapshot date (one row per blog per day) |
| `views` | `INTEGER` | NOT NULL, default `0` | Total page views |
| `unique_visitors` | `INTEGER` | NOT NULL, default `0` | Unique visitor count |
| `avg_time_on_page_secs` | `INTEGER` | nullable | Average seconds on page |
| `bounce_rate` | `NUMERIC(5,2)` | nullable | Percentage bounce rate |
| `backlinks` | `INTEGER` | NOT NULL, default `0` | External inbound links |
| `search_rank_score` | `NUMERIC(5,2)` | nullable | 0–100 SERP ranking score |
| `promotion_ease_score` | `NUMERIC(5,2)` | nullable | 0–100 shareability score |
| `social_shares` | `INTEGER` | NOT NULL, default `0` | Aggregate shares across platforms |
| `referrer_breakdown` | `JSONB` | nullable | `{"google": 120, "twitter": 40, ...}` |
| `source` | `VARCHAR(50)` | NOT NULL, default `'internal'` | Where data came from (e.g. `google_analytics`, `plausible`) |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | — |

**Unique constraint:** `(blog_id, recorded_date)`  
**Indexes:** `blog_id`, `recorded_date`

---

## 10. `third_party_integrations`

Tracks every external service connected to the app (analytics, CMS, email, AI, etc.).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | PK | Primary key |
| `user_id` | `UUID` | FK → `users.id`, nullable | User-level integration (null = system-level) |
| `provider` | `VARCHAR(60)` | NOT NULL | e.g. `google_analytics`, `mailchimp`, `openai`, `cloudinary` |
| `provider_type` | `integration_type` (enum) | NOT NULL | Broad category of service |
| `label` | `VARCHAR(120)` | nullable | Friendly name shown in UI |
| `config` | `JSONB` | NOT NULL, default `'{}'` | Non-sensitive config (tracking IDs, workspace slugs, etc.) |
| `credentials` | `JSONB` | nullable, encrypted | Sensitive keys/tokens — encrypted at rest |
| `status` | `integration_status` (enum) | NOT NULL, default `'inactive'` | Connection state |
| `last_tested_at` | `TIMESTAMPTZ` | nullable | Last successful health check |
| `error_message` | `TEXT` | nullable | Most recent error from the provider |
| `metadata` | `JSONB` | nullable | Provider-specific extra data |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | — |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | — |

**Indexes:** `user_id`, `provider`, `status`

---

## 11. `integration_events`

Audit log for all events fired to or received from third-party integrations.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | PK | Primary key |
| `integration_id` | `UUID` | FK → `third_party_integrations.id`, NOT NULL | Which integration |
| `blog_id` | `UUID` | FK → `blogs.id`, nullable | Related blog (if any) |
| `event_type` | `VARCHAR(80)` | NOT NULL | e.g. `blog.published`, `analytics.synced`, `email.sent` |
| `direction` | `VARCHAR(10)` | NOT NULL | `outbound` or `inbound` |
| `payload` | `JSONB` | nullable | Request/response body |
| `status_code` | `SMALLINT` | nullable | HTTP status code from provider |
| `success` | `BOOLEAN` | NOT NULL, default `true` | Outcome |
| `error_message` | `TEXT` | nullable | Error detail on failure |
| `duration_ms` | `INTEGER` | nullable | API call duration in milliseconds |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | — |

**Indexes:** `integration_id`, `blog_id`, `event_type`, `created_at`

---

## 12. `api_webhooks`

Outbound webhooks that notify other systems when blog events occur.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | PK | Primary key |
| `user_id` | `UUID` | FK → `users.id`, NOT NULL | Owner |
| `name` | `VARCHAR(120)` | NOT NULL | Human-readable label |
| `target_url` | `TEXT` | NOT NULL | Endpoint to POST events to |
| `secret` | `TEXT` | NOT NULL, encrypted | HMAC signing secret |
| `events` | `TEXT[]` | NOT NULL | Array of subscribed event names |
| `is_active` | `BOOLEAN` | NOT NULL, default `true` | Enabled flag |
| `last_triggered_at` | `TIMESTAMPTZ` | nullable | Most recent delivery |
| `failure_count` | `SMALLINT` | NOT NULL, default `0` | Consecutive failures (disable after threshold) |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | — |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL, default `now()` | — |

**Indexes:** `user_id`, `is_active`

---

## Relationships Summary

```
users ──────────────< blogs                (one user writes many blogs)
users ──────────────< user_socials         (one user has many social handles)
social_platforms ───< user_socials         (one platform referenced by many users)
templates ──────────< blogs                (one template applied to many blogs)
blogs ──────────────< blog_topics          (one blog tagged with many topics)
topics ─────────────< blog_topics          (one topic on many blogs)
blogs ──────────────< images               (one blog contains many images)
users ──────────────< images               (one user uploads many images)
blogs ──────────────< blog_analytics       (one blog has many daily snapshots)
users ──────────────< third_party_integrations
third_party_integrations ──< integration_events
blogs ──────────────< integration_events   (optional link)
users ──────────────< api_webhooks
topics ─────────────< topics               (self-referential: sub-topics)
```

---

## Enums Reference

### `user_role`
| Value | Description |
|---|---|
| `owner` | Full access — dashboard, all blogs, all settings |
| `admin` | Can manage all blogs and users |
| `user` | Can create and manage own blogs |
| `visitor` | Read-only access |

### `blog_status`
| Value | Description |
|---|---|
| `draft` | Work in progress, not visible publicly |
| `review` | Submitted for editorial review |
| `scheduled` | Queued for future publish via `scheduled_at` |
| `published` | Live and publicly visible |
| `archived` | Hidden from public, retained in records |

### `integration_type`
| Value | Description |
|---|---|
| `analytics` | Google Analytics, Plausible, Fathom, etc. |
| `email` | Mailchimp, ConvertKit, Brevo, etc. |
| `social` | Auto-posting to social platforms |
| `ai` | OpenAI, Anthropic, Cohere, etc. |
| `storage` | Cloudinary, S3, Uploadcare, etc. |
| `seo` | Ahrefs, SEMrush, Google Search Console |
| `cms` | Contentful, Sanity, Strapi sync |
| `payment` | Stripe, Paddle (for premium features) |
| `notification` | Slack, Discord, push notification services |
| `custom` | Any other third-party API |

### `integration_status`
| Value | Description |
|---|---|
| `active` | Connected and healthy |
| `inactive` | Disconnected or not yet configured |
| `error` | Connected but last call failed |
| `revoked` | Credentials expired or revoked by provider |

---

## Integration Design Notes

### Third-party API readiness

The schema is designed to accommodate any external API without structural changes:

**Analytics providers** (Google Analytics, Plausible, Fathom, Umami)
- Connect via `third_party_integrations` with `provider_type = 'analytics'`
- Push daily data into `blog_analytics.referrer_breakdown` (JSONB) and set `source` to the provider slug
- One blog can have data rows from multiple sources on the same date

**Social auto-posting** (Buffer, Hootsuite, native platform APIs)
- OAuth tokens stored in `user_socials.access_token` (encrypted)
- Each publish action logs to `integration_events` with `event_type = 'blog.shared'`

**AI/content tools** (OpenAI, Anthropic, Grammarly)
- Credentials stored in `third_party_integrations.credentials` (JSONB, encrypted)
- Responses or enrichment metadata stored in `integration_events.payload`

**Storage/CDN** (Cloudinary, AWS S3, Uploadcare)
- `images.storage_key` holds the internal path/asset ID
- `images.url` holds the public CDN URL
- Provider config stored in `third_party_integrations`

**Webhooks (inbound)**
- Inbound events from providers (e.g. Stripe payment confirmed, Search Console ranking updated) are recorded in `integration_events` with `direction = 'inbound'`

**Webhooks (outbound)**
- Your app fires events to user-defined endpoints via `api_webhooks`
- Subscribed events array (e.g. `["blog.published", "blog.updated"]`) drives the dispatcher
- HMAC signature generated from `api_webhooks.secret` and sent in `X-Signature-256` header

### JSONB fields

| Table | Column | Schema hint |
|---|---|---|
| `templates` | `layout_config` | Component tree, font config, colour palette |
| `blog_analytics` | `referrer_breakdown` | `{ "source_name": integer_count }` |
| `third_party_integrations` | `config` | Non-sensitive provider settings |
| `third_party_integrations` | `credentials` | Encrypted tokens, API keys |
| `integration_events` | `payload` | Raw request + response body |

### Encryption guidance

Fields that must be encrypted at rest: `user_socials.access_token`, `user_socials.refresh_token`, `third_party_integrations.credentials`, `api_webhooks.secret`. Use `pgcrypto` (`pgp_sym_encrypt`) or application-level encryption (AES-256-GCM) with keys stored in a secrets manager (AWS Secrets Manager, HashiCorp Vault).

---

*Schema version 1.0.0 — extend `third_party_integrations` rows, not columns, to add new providers.*