import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "eyeOpen", "eyeClosed"]

  toggle() {
    const showing = this.inputTarget.type === "text"
    this.inputTarget.type = showing ? "password" : "text"

    if (this.hasEyeOpenTarget && this.hasEyeClosedTarget) {
      this.eyeOpenTarget.hidden   = showing
      this.eyeClosedTarget.hidden = !showing
    }
  }
}
