import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "payload"]

  toggle(event) {
    const idx = event.currentTarget.dataset.index
    const payload = this.payloadTargets.find((el) => el.dataset.index === idx)
    if (payload) payload.classList.toggle("hidden")
  }
}
