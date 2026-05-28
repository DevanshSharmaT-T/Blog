import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "wordCount", "readTime"]
  static values  = { uniqueId: { type: String, default: "new" } }

  connect() {
    if (typeof EasyMDE === "undefined") {
      this.retryTimer = setTimeout(() => this.connect(), 200)
      return
    }

    this.editor = new EasyMDE({
      element: this.textareaTarget,
      spellChecker: false,
      autosave: { enabled: true, uniqueId: `blog_${this.uniqueIdValue}`, delay: 60000 },
      toolbar: ["bold","italic","heading","|","quote","unordered-list","ordered-list","|","link","image","|","preview","guide"],
      status: false
    })

    this.changeHandler = () => this.updateMeta()
    this.editor.codemirror.on("change", this.changeHandler)
    this.updateMeta()
  }

  disconnect() {
    if (this.retryTimer) clearTimeout(this.retryTimer)
    if (this.editor) {
      try { this.editor.toTextArea() } catch (_) {}
      this.editor = null
    }
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
