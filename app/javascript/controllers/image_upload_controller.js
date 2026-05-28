import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "fileInput", "urlField", "preview", "image", "spinner", "error"]
  static values  = { endpoint: { type: String, default: "/uploads" } }

  connect() {
    if (this.hasDropzoneTarget) {
      this.onDragOver  = (e) => { e.preventDefault(); this.dropzoneTarget.classList.add("border-violet-500", "bg-violet-500/5") }
      this.onDragLeave = ()  => { this.dropzoneTarget.classList.remove("border-violet-500", "bg-violet-500/5") }
      this.onDrop      = (e) => {
        e.preventDefault()
        this.onDragLeave()
        const file = e.dataTransfer.files && e.dataTransfer.files[0]
        if (file) this.handleFile(file)
      }
      this.dropzoneTarget.addEventListener("dragover", this.onDragOver)
      this.dropzoneTarget.addEventListener("dragleave", this.onDragLeave)
      this.dropzoneTarget.addEventListener("drop", this.onDrop)
    }
  }

  disconnect() {
    if (this.hasDropzoneTarget && this.onDragOver) {
      this.dropzoneTarget.removeEventListener("dragover", this.onDragOver)
      this.dropzoneTarget.removeEventListener("dragleave", this.onDragLeave)
      this.dropzoneTarget.removeEventListener("drop", this.onDrop)
    }
  }

  pickFile() { if (this.hasFileInputTarget) this.fileInputTarget.click() }

  fileChosen() {
    const file = this.fileInputTarget.files && this.fileInputTarget.files[0]
    if (file) this.handleFile(file)
  }

  async handleFile(file) {
    this.clearError()

    if (!file.type.startsWith("image/")) {
      this.showError("Please upload an image file.")
      return
    }
    if (file.size > 10 * 1024 * 1024) {
      this.showError("Image must be under 10 MB.")
      return
    }

    this.showSpinner(true)

    try {
      const formData = new FormData()
      formData.append("file", file)

      const csrfMeta = document.querySelector('meta[name="csrf-token"]')
      const headers  = { "Accept": "application/json" }
      if (csrfMeta) headers["X-CSRF-Token"] = csrfMeta.content

      const response = await fetch(this.endpointValue, {
        method: "POST",
        headers,
        credentials: "same-origin",
        body: formData
      })

      if (!response.ok) {
        const text = await response.text()
        throw new Error(`Upload failed (${response.status}): ${text.slice(0, 120)}`)
      }

      const data = await response.json()
      const url  = data.url || data.secure_url || (data.image && data.image.url)
      if (!url) throw new Error("Upload succeeded but no URL returned.")

      if (this.hasUrlFieldTarget) {
        this.urlFieldTarget.value = url
        this.urlFieldTarget.dispatchEvent(new Event("input", { bubbles: true }))
      }
      if (this.hasImageTarget)   this.imageTarget.src = url
      if (this.hasPreviewTarget) this.previewTarget.classList.remove("hidden")
    } catch (err) {
      this.showError(err.message || "Image upload failed.")
    } finally {
      this.showSpinner(false)
    }
  }

  showSpinner(on) {
    if (!this.hasSpinnerTarget) return
    this.spinnerTarget.classList.toggle("hidden", !on)
  }

  showError(message) {
    if (!this.hasErrorTarget) return
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  clearError() {
    if (!this.hasErrorTarget) return
    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }
}
