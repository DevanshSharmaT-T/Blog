import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "wordCount", "readTime"]
  static values  = { uniqueId: { type: String, default: "new" }, uploadUrl: String }

  connect() {
    if (typeof EasyMDE === "undefined") {
      this.retryTimer = setTimeout(() => this.connect(), 200)
      return
    }

    const toolbar = ["bold","italic","heading","|","quote","unordered-list","ordered-list","|","link","image"]
    const options = {
      element: this.textareaTarget,
      spellChecker: false,
      autosave: { enabled: true, uniqueId: `blog_${this.uniqueIdValue}`, delay: 60000 },
      status: false
    }

    // Direct image upload (drag-drop / paste / toolbar) → inserts ![](url) at the cursor.
    if (this.hasUploadUrlValue && this.uploadUrlValue) {
      toolbar.push("upload-image")
      options.uploadImage = true
      options.imageMaxSize = 10 * 1024 * 1024
      options.imageAccept = "image/png,image/jpeg,image/webp,image/gif"
      options.imageUploadFunction = (file, onSuccess, onError) => this.uploadImage(file, onSuccess, onError)
    }

    options.toolbar = [...toolbar, "|", "preview", "guide"]
    this.editor = new EasyMDE(options)

    this.changeHandler = () => this.updateMeta()
    this.editor.codemirror.on("change", this.changeHandler)

    // Insert an already-uploaded gallery image at the cursor (dispatched by image-gallery).
    this.insertHandler = (e) => this.insertImage(e.detail || {})
    document.addEventListener("blog-image:insert", this.insertHandler)

    // Hand the current content to whoever asks (image-gallery cleanup), synchronously.
    this.contentHandler = (e) => { if (e.detail && e.detail.setContent) e.detail.setContent(this.editor ? this.editor.value() : "") }
    document.addEventListener("blog-image:get-content", this.contentHandler)

    this.updateMeta()
  }

  disconnect() {
    if (this.retryTimer) clearTimeout(this.retryTimer)
    if (this.insertHandler) document.removeEventListener("blog-image:insert", this.insertHandler)
    if (this.contentHandler) document.removeEventListener("blog-image:get-content", this.contentHandler)
    if (this.editor) {
      try { this.editor.toTextArea() } catch (_) {}
      this.editor = null
    }
  }

  insertImage({ url, alt }) {
    if (!this.editor || !url) return
    const cm = this.editor.codemirror
    cm.replaceSelection(`![${alt || ""}](${url})`)
    cm.focus()
  }

  uploadImage(file, onSuccess, onError) {
    const formData = new FormData()
    formData.append("file", file)

    const meta = document.querySelector('meta[name="csrf-token"]')
    const headers = { "Accept": "application/json" }
    if (meta) headers["X-CSRF-Token"] = meta.content

    fetch(this.uploadUrlValue, { method: "POST", headers, credentials: "same-origin", body: formData })
      .then((r) => (r.ok ? r.json() : r.text().then((t) => Promise.reject(t))))
      .then((data) => {
        if (data.url) onSuccess(data.url)
        else onError("Upload succeeded but no URL returned.")
      })
      .catch((err) => onError(typeof err === "string" ? err : "Image upload failed."))
  }

  updateMeta() {
    if (!this.editor) return
    const text = this.editor.value() || ""
    const words = text.split(/\s+/).filter(Boolean).length
    if (this.hasWordCountTarget) this.wordCountTarget.textContent = `${words} words`
    if (this.hasReadTimeTarget) {
      const mins = Math.max(1, Math.ceil(words / 200))
      this.readTimeTarget.textContent = `~${mins} min read`
    }
  }
}
