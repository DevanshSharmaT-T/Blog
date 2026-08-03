import { Controller } from "@hotwired/stimulus"

// Keeps an image preview in sync with a URL field. When a value is present it
// shows the preview (and, when those targets exist, hides the dropzone + URL
// field so only the thumbnail remains). `remove` clears the value to detach the
// image and bring the uploader back.
//
// The preview doubles as a focal-point picker: dragging inside the frame sets
// the cover's object-position (stored as x/y percentages in hidden fields) so
// the author controls which part of the image stays visible when it is cropped.
export default class extends Controller {
  static targets = ["input", "preview", "image", "anchor", "dropzone", "field", "picker", "marker", "focalX", "focalY"]

  connect() {
    this.render()
    this.applyFocal()
  }

  input() { this.render() }

  remove() {
    if (!this.hasInputTarget) return
    this.inputTarget.value = ""
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this.setFocal(50, 50)
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
      this.applyFocal()
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

  // ── Focal-point picker ──────────────────────────────────────────────

  startDrag(event) {
    if (!this.hasPickerTarget) return
    this.dragging = true
    this.pickerTarget.setPointerCapture?.(event.pointerId)
    this.drag(event)
  }

  drag(event) {
    if (!this.dragging) return
    event.preventDefault()
    const rect = this.pickerTarget.getBoundingClientRect()
    const x = this.clamp(((event.clientX - rect.left) / rect.width) * 100)
    const y = this.clamp(((event.clientY - rect.top) / rect.height) * 100)
    this.setFocal(x, y)
  }

  endDrag(event) {
    this.dragging = false
    this.pickerTarget?.releasePointerCapture?.(event.pointerId)
  }

  // Read the current focal values and apply them to the image + marker.
  applyFocal() {
    const x = this.hasFocalXTarget ? parseFloat(this.focalXTarget.value) : 50
    const y = this.hasFocalYTarget ? parseFloat(this.focalYTarget.value) : 50
    this.setFocal(isNaN(x) ? 50 : x, isNaN(y) ? 50 : y)
  }

  setFocal(x, y) {
    const rx = Math.round(x * 100) / 100
    const ry = Math.round(y * 100) / 100
    if (this.hasFocalXTarget) this.focalXTarget.value = rx
    if (this.hasFocalYTarget) this.focalYTarget.value = ry
    if (this.hasImageTarget)  this.imageTarget.style.objectPosition = `${rx}% ${ry}%`
    if (this.hasMarkerTarget) {
      this.markerTarget.style.left = `${rx}%`
      this.markerTarget.style.top  = `${ry}%`
    }
  }

  clamp(n) { return Math.max(0, Math.min(100, n)) }
}
