import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter", "bar"]
  static values  = { max: { type: Number, default: 160 } }

  connect() { this.update() }
  input()   { this.update() }

  update() {
    if (!this.hasInputTarget) return
    const len = this.inputTarget.value.length
    const max = this.maxValue
    if (this.hasCounterTarget) this.counterTarget.textContent = String(len)

    if (this.hasBarTarget) {
      const pct = Math.min(100, (len / max) * 100)
      this.barTarget.style.width = `${pct}%`
      const ratio = len / max
      this.barTarget.classList.remove("bg-emerald-500", "bg-amber-500", "bg-red-500")
      if (ratio < 0.7)       this.barTarget.classList.add("bg-emerald-500")
      else if (ratio < 0.9)  this.barTarget.classList.add("bg-amber-500")
      else                   this.barTarget.classList.add("bg-red-500")
    }
  }
}
