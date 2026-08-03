import { Controller } from "@hotwired/stimulus"

// Searchable grid icon picker for the Topic form.
// - `field`  : the hidden input that stores the selected icon name.
// - `search` : text input used to filter tiles by name.
// - `tile`   : one button per available icon (data-name="<icon>").
export default class extends Controller {
  static targets = ["field", "search", "tile"]

  connect() {
    this.highlight(this.fieldTarget.value)
  }

  select(event) {
    const name = event.currentTarget.dataset.name
    this.fieldTarget.value = name
    this.highlight(name)
  }

  filter() {
    const q = this.searchTarget.value.trim().toLowerCase()
    this.tileTargets.forEach(tile => {
      tile.hidden = q !== "" && !tile.dataset.name.toLowerCase().includes(q)
    })
  }

  highlight(name) {
    this.tileTargets.forEach(tile => {
      tile.classList.toggle("is-selected", tile.dataset.name === name)
    })
  }
}
