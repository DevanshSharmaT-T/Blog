import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 4000 } }

  connect() {
    this.timer = setTimeout(() => this.dismiss(), this.delayValue)
  }

  disconnect() {
    if (this.timer) clearTimeout(this.timer)
  }

  close() { this.dismiss() }

  dismiss() {
    this.element.style.transition = "all 0.4s ease"
    this.element.style.opacity    = "0"
    this.element.style.transform  = "translateY(-1rem)"
    setTimeout(() => this.element.remove(), 400)
  }
}
