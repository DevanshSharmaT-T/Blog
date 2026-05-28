import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "image"]

  connect() { this.render() }
  input()   { this.render() }

  render() {
    if (!this.hasInputTarget) return
    const value = this.inputTarget.value
    if (value) {
      if (this.hasImageTarget) this.imageTarget.src = value
      if (this.hasPreviewTarget) this.previewTarget.classList.remove("hidden")
    } else if (this.hasPreviewTarget) {
      this.previewTarget.classList.add("hidden")
    }
  }
}
