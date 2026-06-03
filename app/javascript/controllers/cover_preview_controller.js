import { Controller } from "@hotwired/stimulus"

// Keeps an image preview in sync with a URL field. When a value is present it
// shows the preview (and, when those targets exist, hides the dropzone + URL
// field so only the thumbnail remains). `remove` clears the value to detach the
// image and bring the uploader back.
export default class extends Controller {
  static targets = ["input", "preview", "image", "anchor", "dropzone", "field"]

  connect() { this.render() }
  input()   { this.render() }

  remove() {
    if (!this.hasInputTarget) return
    this.inputTarget.value = ""
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  render() {
    if (!this.hasInputTarget) return
    const value = this.inputTarget.value

    if (value) {
      if (this.hasImageTarget)  this.imageTarget.src = value
      if (this.hasAnchorTarget) this.anchorTarget.href = value
      this.toggle(this.previewTarget, true,  "hasPreviewTarget")
      this.toggle(this.dropzoneTarget, false, "hasDropzoneTarget")
      this.toggle(this.fieldTarget,    false, "hasFieldTarget")
    } else {
      this.toggle(this.previewTarget, false, "hasPreviewTarget")
      this.toggle(this.dropzoneTarget, true,  "hasDropzoneTarget")
      this.toggle(this.fieldTarget,    true,  "hasFieldTarget")
    }
  }

  toggle(el, show, hasTargetProp) {
    if (!this[hasTargetProp]) return
    el.classList.toggle("hidden", !show)
  }
}
