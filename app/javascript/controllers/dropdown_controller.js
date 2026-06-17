import { Controller } from "@hotwired/stimulus"

// Lightweight toggle menu (e.g. a kebab "⋯" actions menu on a table row).
//
//   <div data-controller="dropdown">
//     <button data-action="dropdown#toggle">⋯</button>
//     <div data-dropdown-target="menu" hidden> … items … </div>
//   </div>
//
// Opens on click, closes on outside-click, Escape, or selecting an item.
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.close = this.close.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.close)
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.hidden ? this.open() : this.close()
  }

  open() {
    this.menuTarget.hidden = false
    document.addEventListener("click", this.close)
    document.addEventListener("keydown", this.onKeydown ||= (e) => {
      if (e.key === "Escape") this.close()
    })
  }

  close(event) {
    // Ignore clicks that land inside the menu or on the toggle button.
    if (event && this.element.contains(event.target)) return
    this.menuTarget.hidden = true
    document.removeEventListener("click", this.close)
    if (this.onKeydown) document.removeEventListener("keydown", this.onKeydown)
  }
}
