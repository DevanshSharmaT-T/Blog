import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  async copy(event) {
    event.preventDefault()
    const text = this.textValue || window.location.href
    try {
      await navigator.clipboard.writeText(text)
      this.flash("Copied!")
    } catch (_) {
      this.flash("Copy failed")
    }
  }

  flash(msg) {
    const original = this.element.dataset.originalLabel || this.element.getAttribute("aria-label") || ""
    this.element.dataset.originalLabel = original
    this.element.setAttribute("aria-label", msg)
    this.element.classList.add("flashed")
    setTimeout(() => {
      this.element.setAttribute("aria-label", original)
      this.element.classList.remove("flashed")
    }, 1400)
  }
}
