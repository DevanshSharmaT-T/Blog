import { Controller } from "@hotwired/stimulus"

// Multi-image gallery for the blog post form. Uploads each dropped/selected
// file to the blog's images endpoint, then renders a deletable tile in a grid.
export default class extends Controller {
  static targets = ["dropzone", "fileInput", "grid", "spinner", "error"]
  static values  = { uploadUrl: String, cleanupUrl: String }

  connect() {
    if (this.hasDropzoneTarget) {
      this.onDragOver  = (e) => { e.preventDefault(); this.dropzoneTarget.classList.add("border-violet-500", "bg-violet-500/5") }
      this.onDragLeave = ()  => { this.dropzoneTarget.classList.remove("border-violet-500", "bg-violet-500/5") }
      this.onDrop      = (e) => {
        e.preventDefault()
        this.onDragLeave()
        this.uploadFiles(e.dataTransfer.files)
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
    this.uploadFiles(this.fileInputTarget.files)
    this.fileInputTarget.value = ""
  }

  async uploadFiles(fileList) {
    const files = Array.from(fileList || [])
    for (const file of files) await this.uploadFile(file)
  }

  async uploadFile(file) {
    this.clearError()

    if (!file.type.startsWith("image/")) { this.showError("Please upload image files only."); return }
    if (file.size > 10 * 1024 * 1024)    { this.showError("Each image must be under 10 MB."); return }

    this.showSpinner(true)
    try {
      const formData = new FormData()
      formData.append("file", file)

      const response = await fetch(this.uploadUrlValue, {
        method: "POST",
        headers: { "Accept": "application/json", ...this.csrfHeader() },
        credentials: "same-origin",
        body: formData
      })

      if (!response.ok) {
        const text = await response.text()
        throw new Error(`Upload failed (${response.status}): ${text.slice(0, 120)}`)
      }

      const data = await response.json()
      if (data.url) this.appendTile(data)
    } catch (err) {
      this.showError(err.message || "Image upload failed.")
    } finally {
      this.showSpinner(false)
    }
  }

  appendTile({ id, url, delete_url }) {
    if (!this.hasGridTarget) return
    const tile = document.createElement("div")
    tile.className = "image-tile relative group aspect-square"
    if (id != null) tile.dataset.imageId = id
    tile.innerHTML = `
      <a href="${url}" target="_blank" rel="noopener">
        <img src="${url}" alt="" class="w-full h-full object-cover rounded-lg border border-gray-200 dark:border-gray-700">
      </a>
      <button type="button" data-action="click->image-gallery#insert" data-url="${url}"
              class="absolute bottom-1 left-1 opacity-0 group-hover:opacity-100 transition-opacity bg-violet-600 hover:bg-violet-700 text-white text-xs rounded px-2 py-0.5"
              title="Insert into content">Insert</button>
      <button type="button" data-action="click->image-gallery#remove" data-delete-url="${delete_url}"
              class="absolute top-1 right-1 opacity-0 group-hover:opacity-100 transition-opacity bg-black/60 hover:bg-red-600 text-white rounded-full w-6 h-6 flex items-center justify-center"
              aria-label="Delete image">
        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
      </button>`
    this.gridTarget.appendChild(tile)
  }

  // Insert an existing gallery image into the markdown editor at the cursor.
  insert(e) {
    const url = e.currentTarget.dataset.url
    if (url) document.dispatchEvent(new CustomEvent("blog-image:insert", { detail: { url } }))
  }

  // Delete gallery images not referenced in the current content (or cover).
  async cleanup() {
    if (!this.hasCleanupUrlValue) return

    // Ask the editor for its current text (synchronous round-trip).
    let content = ""
    document.dispatchEvent(new CustomEvent("blog-image:get-content", { detail: { setContent: (c) => { content = c || "" } } }))

    if (!confirm("Delete all images not used in the content? This can't be undone.")) return

    this.clearError()
    try {
      const response = await fetch(this.cleanupUrlValue, {
        method: "DELETE",
        headers: { "Accept": "application/json", "Content-Type": "application/json", ...this.csrfHeader() },
        credentials: "same-origin",
        body: JSON.stringify({ content })
      })
      if (!response.ok) throw new Error("Cleanup failed.")
      const data = await response.json()
      ;(data.removed_ids || []).forEach((id) => {
        this.gridTarget.querySelector(`.image-tile[data-image-id="${id}"]`)?.remove()
      })
    } catch (err) {
      this.showError(err.message || "Could not remove unused images.")
    }
  }

  async remove(e) {
    const button = e.currentTarget
    const url    = button.dataset.deleteUrl
    if (!url) return

    try {
      const response = await fetch(url, {
        method: "DELETE",
        headers: { "Accept": "application/json", ...this.csrfHeader() },
        credentials: "same-origin"
      })
      if (!response.ok) throw new Error("Delete failed.")
      button.closest(".image-tile")?.remove()
    } catch (err) {
      this.showError(err.message || "Could not delete image.")
    }
  }

  csrfHeader() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? { "X-CSRF-Token": meta.content } : {}
  }

  showSpinner(on) {
    if (this.hasSpinnerTarget) this.spinnerTarget.classList.toggle("hidden", !on)
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
