import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["titleInput", "slugInput", "preview"]
  static values  = { locked: { type: Boolean, default: false } }

  connect() {
    if (this.hasSlugInputTarget && this.slugInputTarget.value.length > 0) {
      this.lockedValue = true
    }
    this.renderPreview()
  }

  titleChanged() {
    if (this.lockedValue) return this.renderPreview()
    const slug = this.parameterize(this.titleInputTarget.value)
    if (this.hasSlugInputTarget) this.slugInputTarget.value = slug
    this.renderPreview()
  }

  slugChanged() {
    if (this.hasSlugInputTarget) {
      this.lockedValue = this.slugInputTarget.value.length > 0
    }
    this.renderPreview()
  }

  renderPreview() {
    if (!this.hasPreviewTarget) return
    const slug = this.hasSlugInputTarget
      ? this.slugInputTarget.value
      : this.parameterize(this.titleInputTarget?.value || "")
    this.previewTarget.textContent = slug || "your-slug-here"
  }

  parameterize(str) {
    return (str || "")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
  }
}
