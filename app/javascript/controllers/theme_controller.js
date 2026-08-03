import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.sync()
  }

  toggle() {
    const current = document.documentElement.dataset.theme || "light"
    const next    = current === "dark" ? "light" : "dark"
    this.apply(next)
  }

  sync() {
    const stored = localStorage.getItem("theme") || this.readCookie("theme")
    if (stored && stored !== document.documentElement.dataset.theme) {
      this.apply(stored)
    }
  }

  apply(theme) {
    document.documentElement.dataset.theme = theme
    try { localStorage.setItem("theme", theme) } catch (_) {}
    document.cookie = `theme=${theme}; path=/; max-age=31536000; samesite=lax`
  }

  readCookie(name) {
    const m = document.cookie.match(new RegExp(`(?:^|; )${name}=([^;]*)`))
    return m ? decodeURIComponent(m[1]) : null
  }
}
