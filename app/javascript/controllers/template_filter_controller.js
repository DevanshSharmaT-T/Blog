import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "chip"]
  static values  = { active: { type: String, default: "all" } }

  connect() { this.apply() }

  filter(event) {
    event.preventDefault()
    this.activeValue = event.currentTarget.dataset.category || "all"
    this.apply()
  }

  apply() {
    const cat = this.activeValue
    this.chipTargets.forEach(chip => {
      chip.classList.toggle("active", (chip.dataset.category || "all") === cat)
    })
    this.cardTargets.forEach(card => {
      const cardCat = card.dataset.category || ""
      card.hidden = cat !== "all" && cardCat !== cat
    })
  }
}
