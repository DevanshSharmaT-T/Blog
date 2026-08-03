<div align="center">

# 📝 MyBlog

### Write. Publish. Grow.

A modern, full-featured **blog & publishing platform** built with **Rails 8** and **Hotwire** — with built-in SEO scoring, smart scheduling, content moderation, analytics, social integrations, and a versioned JSON API.

<br/>

[![Ruby](https://img.shields.io/badge/Ruby-3.4.8-CC342D?logo=ruby&logoColor=white)](.ruby-version)
[![Rails](https://img.shields.io/badge/Rails-8.1.3-D30001?logo=rubyonrails&logoColor=white)](Gemfile)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)](config/database.yml)
[![Hotwire](https://img.shields.io/badge/Hotwire-Turbo%20%2B%20Stimulus-5CB85C?logo=hotwire&logoColor=white)](https://hotwired.dev)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-3-38B2AC?logo=tailwindcss&logoColor=white)](https://tailwindcss.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#contributing)

</div>

---

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Testing & Quality](#testing--quality)
- [Deployment](#deployment)
- [REST API](#rest-api)
- [Data Model](#data-model)
- [Project Structure](#project-structure)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Author](#author)

---

## Features

MyBlog is a complete publishing engine, not just a CRUD demo. Highlights:

**✍️ Authoring & Publishing**
- 📝 **Markdown or HTML** authoring with **Rouge**-highlighted code blocks.
- 🔄 Full publishing lifecycle: `draft → review → scheduled → published → archived`, with **soft-delete**.
- ⏰ **Smart scheduling** — set a publish time and let a background job (`ScheduledPublishJob`, Solid Queue) auto-publish it.
- ⚡ Auto-generated **slugs**, **word count**, and **reading time** on every save.
- 🧩 Reusable **post templates** to kickstart new articles.

**🔍 SEO & Discovery**
- 📊 Real-time **SEO / readability / promotion scoring** (0–100) as you write, via `ScoringService`.
- 🌐 **Sitemap** (`/sitemap.xml`), **Atom feed** (`/blog/feed`), canonical URLs, JSON-LD structured data, and Open Graph / Twitter cards.
- 🏷️ **Topics** — hierarchical categories/tags with colors and icons.

**🛡️ Content Moderation**
- 🚫 Automatic flagging of banned words and disposable-email signups (offline, deterministic validators).
- ✅ Admin **moderation queue** with `clean / flagged / approved` states — flagged content stays private until approved.

**👥 Users, Roles & Admin**
- 🔐 **Devise** authentication with email confirmation, password recovery, and remember-me.
- 🎛️ **Role-based access** (`owner / admin / user / visitor`) enforced by **CanCanCan**.
- 🧑‍💼 Admin user management: activate/deactivate, change role, verify, restore, resend confirmation, send password reset.
- 🪪 **Public author profiles** at `/@:username` with prioritized social links; posts at `/@:username/blog/:slug`.

**📈 Analytics & Integrations**
- 📉 Per-post **analytics dashboard** with async view recording and **Chartkick** time-series charts.
- 🔌 **Third-party integrations** with AES-256-GCM **encrypted credentials** and test-connection support.
- 📤 **Outbound webhooks** with delivery logs and per-event retry.

**🧑‍💻 Developer Experience**
- 🧵 **Versioned JSON REST API** (`/api/v1`) with JWT auth, CORS, and Rack::Attack rate limiting.
- 📱 **PWA** support (installable, offline-ready), light/dark theme, and a `/up` health check.
- 🧰 DB-backed **Solid Queue / Cache / Cable** — no Redis required to run.

---

## Screenshots

> [!NOTE]
> Drop your images into [`docs/screenshots/`](docs/screenshots) using the filenames below and they'll render here automatically. See [`docs/screenshots/README.md`](docs/screenshots/README.md) for the shot list.

<div align="center">

<img src="docs/screenshots/hero.png" alt="MyBlog home page" width="800" />

<br/><br/>

<img src="docs/screenshots/editor.png" alt="Post editor with live SEO scoring" width="49%" />
<img src="docs/screenshots/dashboard.png" alt="Analytics dashboard" width="49%" />

</div>

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Language / Framework** | Ruby 3.4.8 · Rails 8.1.3 |
| **Database** | PostgreSQL (UUID primary keys, `pgcrypto`) |
| **Web server** | Puma · Thruster (asset caching/compression) |
| **Frontend** | Hotwire (Turbo + Stimulus) · Tailwind CSS · Propshaft · Importmap (no Node build) |
| **Auth** | Devise (confirmable) · CanCanCan (roles) · JWT (API) · bcrypt |
| **Background jobs / cache / cable** | Solid Queue · Solid Cache · Solid Cable (all DB-backed) |
| **Content** | Redcarpet (Markdown) · Rouge (syntax highlighting) · Nokogiri |
| **Media** | Cloudinary (primary) · ImageKit / AWS S3 (optional) · image_processing (libvips) |
| **Search / data / charts** | Ransack · Pagy · Chartkick · Groupdate |
| **API / security** | rack-cors · rack-attack · HTTParty |
| **Deployment** | Docker · Kamal · Render |
| **Quality** | Minitest · Capybara + Selenium · Brakeman · bundler-audit · RuboCop (omakase) |

---

## Getting Started

### Prerequisites

- **Ruby 3.4.8** (see [`.ruby-version`](.ruby-version) / [`Dockerfile`](Dockerfile))
- **PostgreSQL 16+** (or use the bundled `docker-compose.yml`)
- **Bundler** (`gem install bundler`)
- No Node.js required — JavaScript ships via Importmap and CSS via the `tailwindcss-rails` binary.

### Quick Start

```bash
# 1. Clone
git clone https://github.com/DevanshSharmaT-T/Blog.git
cd Blog

# 2. Start PostgreSQL (Redis is optional — the app is fully DB-backed)
docker compose up -d

# 3. Configure environment
cp .env.example .env        # then fill in your secrets

# 4. One-shot setup: installs gems, prepares the DB, and boots the app on http://localhost:3000
bin/setup
```

`bin/setup` runs `bundle install`, `bin/rails db:prepare` (create + migrate + seed), clears logs/tmp, and launches `bin/dev`.

### Manual Setup

Prefer to run each step yourself?

```bash
bundle install
bin/rails db:prepare        # create, migrate, and seed
bin/dev                     # starts Puma + Tailwind watch on http://localhost:3000
```

> [!WARNING]
> `.env.example` ships `DATABASE_URL` pointing at a **production-named** database (`myblog_production`). Rails honors `DATABASE_URL` if it's set, which can point your local/test runs at that database. **Remove or comment out `DATABASE_URL` locally** so `config/database.yml`'s `myblog_development` / `myblog_test` take effect — and never run destructive `db:` tasks against the production-named database.

The seed data creates an owner account and demo content — check [`db/seeds.rb`](db/seeds.rb) for the credentials (`OWNER_EMAIL` and the password from encrypted credentials).

---

## Configuration

Locally, environment variables are loaded from `.env` via `dotenv-rails`. In **production**, secrets come from Rails encrypted credentials (`bin/rails credentials:edit`) — see the notes in [`render.yaml`](render.yaml). Key variables (full list in [`.env.example`](.env.example)):

**Database**

| Variable | Purpose |
|----------|---------|
| `DB_HOST` / `DB_PORT` | PostgreSQL host & port (default `localhost:5432`) |
| `DB_USERNAME` / `DB_PASSWORD` | PostgreSQL credentials |
| `RAILS_MAX_THREADS` | Connection pool size (default `5`) |

**Rails & Auth**

| Variable | Purpose |
|----------|---------|
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` (required in production) |
| `SECRET_KEY_BASE` | Rails secret key base |
| `DEVISE_SECRET_KEY` | Devise secret |
| `JWT_SECRET` | Signing key for JSON API tokens |
| `ENCRYPTION_KEY` | 32-byte hex key (AES-256-GCM) for integration credentials — `openssl rand -hex 32` |

**Media & Email**

| Variable | Purpose |
|----------|---------|
| `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_API_KEY` / `CLOUDINARY_API_SECRET` | Cloudinary image storage/CDN |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_REGION` / `AWS_S3_BUCKET` | Optional S3 fallback |
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASS` / `SMTP_SENDER` | SMTP (Brevo) for Devise confirmation emails |

**Optional third-party** (also configurable via the in-app Integrations UI): `GOOGLE_ANALYTICS_ID`, `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`.

---

## Testing & Quality

```bash
bin/rails test              # unit & integration tests (Minitest)
bin/rails test:system       # system tests (Capybara + Selenium)
bin/ci                      # full local CI: RuboCop + audits + Brakeman + tests
```

`bin/ci` mirrors the GitHub Actions pipeline in [`.github/workflows/ci.yml`](.github/workflows/ci.yml):

- 🎨 **RuboCop** — `rubocop-rails-omakase` style
- 🔒 **bundler-audit** — known gem CVEs
- 🔒 **importmap audit** — JavaScript dependency vulnerabilities
- 🔒 **Brakeman** — static security analysis
- ✅ **Minitest** — the test suite

---

## Deployment

Three deployment paths are wired up. **Render** (Docker) is the primary target.

### Render (primary)

Configured via [`render.yaml`](render.yaml) — deploys the `Dockerfile` from the `Deployment` branch with a `/up` health check and `autoDeploy` on.

> [!IMPORTANT]
> Set `RAILS_MASTER_KEY` as a secret in the Render dashboard, and set `region` to match your PostgreSQL region. Do **not** add a `DATABASE_URL` env var — the production DB connection comes from encrypted credentials and `DATABASE_URL` would override it.

### Docker

```bash
docker build -t my_blog .
docker run -d -p 80:80 -e RAILS_MASTER_KEY=<your_key> --name my_blog my_blog
```

The image runs as a non-root user, precompiles assets, and runs `db:prepare` on boot.

### Kamal

A [`config/deploy.yml`](config/deploy.yml) is included for [Kamal](https://kamal-deploy.org) zero-downtime deploys (`bin/kamal deploy`). Update the server IP and container registry before use.

---

## REST API

A versioned JSON API is available under `/api/v1`, authenticated with **JWT** (obtained after email verification), CORS-enabled, and rate-limited via Rack::Attack.

| Resource | Endpoints |
|----------|-----------|
| **Blogs** | CRUD + `publish`, `schedule`, `submit_review` |
| **Topics** | CRUD |
| **Templates** | CRUD |
| **Images** | Upload & manage |
| **Analytics** | `show`, `sync` |
| **Current user** | `/users/me` + socials |
| **Integrations** | CRUD + test connection |
| **Webhooks** | CRUD + delivery logs |

See [`config/routes.rb`](config/routes.rb) and `app/controllers/api/v1/` for the full surface.

---

## Data Model

The database uses PostgreSQL with UUID primary keys, soft deletes, and UTC timestamps across 12 core tables (users, blogs, topics, templates, images, analytics, integrations, webhooks, and more).

📖 **Full schema documentation:** [`SCHEMA.md`](SCHEMA.md)

---

## Project Structure

```
app/
├── controllers/        # Web + api/v1 controllers
├── models/             # Blog, User, Topic, Template, Ability (CanCanCan), …
├── services/           # ContentModeration, ScoringService, WebhookDispatcher,
│                       #   ImageStorage, EncryptionService, RougeRenderer
├── javascript/
│   └── controllers/    # ~20 Stimulus controllers (markdown editor, theme, …)
├── jobs/               # ScheduledPublishJob, WebhookDispatchJob, RecordViewJob
└── views/              # Public reader UI + authenticated sidebar app
config/
├── routes.rb           # Web, public profiles, and /api/v1 routes
├── database.yml        # Primary + Solid Queue/Cache/Cable connections
└── deploy.yml          # Kamal deployment
db/
├── migrate/            # 18 migrations (pgcrypto, enums, UUID tables)
└── seeds.rb            # Owner account, topics, demo content
```

---

## Roadmap

- 💬 Reader **comments** & threaded discussion
- 🔔 In-app **notifications**
- 🔎 Full-text **search** across posts

Have an idea? [Open an issue](https://github.com/DevanshSharmaT-T/Blog/issues).

---

## Contributing

Contributions are welcome! To get started:

1. Fork the repository and create a feature branch.
2. Run `bin/ci` locally and make sure it's green.
3. Open a pull request describing your change.

---

## License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for details.

---

## Author

**Devansh Sharma**

[![GitHub](https://img.shields.io/badge/GitHub-DevanshSharmaT--T-181717?logo=github&logoColor=white)](https://github.com/DevanshSharmaT-T)

<div align="center">
<sub>Built with ❤️ using Rails 8 & Hotwire. If you find this project useful, consider giving it a ⭐.</sub>
</div>
