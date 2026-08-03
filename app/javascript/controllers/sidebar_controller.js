import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const collapsed = this.element.classList.toggle("sidebar-collapsed")
    document.cookie = `sidebar_collapsed=${collapsed}; path=/; max-age=31536000; samesite=lax`
  }
}
