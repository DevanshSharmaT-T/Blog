import { Controller } from "@hotwired/stimulus"

// Interactive, debounced field validation. Mounted ONCE on a <form>; each input
// it should watch carries `data-field-validator-target="input"` and its own
// `data-field-validator-kind` ("text" | "email" | "flaggable"). As the user
// types, the value is POSTed to /moderation/check and the verdict is rendered
// inline into the field's `.form-error` element — no full page reload.
//
// Hard "error" verdicts (banned name/username, disposable email) disable the
// form's submit button; "warning" verdicts (flagged blog content) only inform.
// Server-side validators remain the real enforcement — this is fast feedback.
//
//   <%= form_with ..., data: { controller: "field-validator",
//        field_validator_url_value: moderation_check_path } do |f| %>
//     <div class="form-group">
//       <%= f.email_field :email, data: {
//             field_validator_target: "input", field_validator_kind: "email",
//             action: "input->field-validator#check blur->field-validator#check" } %>
//       <p class="form-error hidden"></p>
//     </div>
//     <%= f.submit "Save", data: { field_validator_target: "submit" } %>
//   <% end %>
export default class extends Controller {
  static targets = ["input", "submit"]
  static values  = { url: String, debounce: { type: Number, default: 350 } }

  connect() {
    this.timers  = new WeakMap()
    this.invalid = new Set()
  }

  disconnect() {
    this.inputTargets.forEach((i) => {
      const t = this.timers.get(i)
      if (t) clearTimeout(t)
    })
  }

  check(event) {
    const input = event.target
    const kind = input.dataset.fieldValidatorKind || "text"

    // Password checks run locally — no server round-trip, no debounce — so the
    // strength meter and match verdict track every keystroke instantly.
    if (kind === "password")     return this.validatePassword(input)
    if (kind === "confirmation") return this.validateConfirmation(input)

    const prev = this.timers.get(input)
    if (prev) clearTimeout(prev)
    this.timers.set(input, setTimeout(() => this.run(input), this.debounceValue))
  }

  // --- Local password validation -------------------------------------------

  validatePassword(input) {
    const value = input.value

    if (!value) {
      this.updateMeter(input, 0)
      this.clear(input)
    } else if (value.length < 6) {
      this.updateMeter(input, this.strengthScore(value))
      this.flag(input, { message: "Password must be at least 6 characters", severity: "error" })
    } else if (value.length > 128) {
      this.updateMeter(input, this.strengthScore(value))
      this.flag(input, { message: "Password must be at most 128 characters", severity: "error" })
    } else {
      const score = this.strengthScore(value)
      this.updateMeter(input, score)
      if (score < 3) {
        this.flag(input, { message: "Weak — add a capital, number, or symbol", severity: "warning" })
      } else {
        this.clear(input)
      }
    }

    // A changed password may make the confirmation match or stop matching.
    const confirmation = this.inputTargets.find(
      (i) => i.dataset.fieldValidatorKind === "confirmation"
    )
    if (confirmation && confirmation.value) this.validateConfirmation(confirmation)
  }

  validateConfirmation(input) {
    if (!input.value) return this.clear(input)

    const password = this.inputTargets.find(
      (i) => i.dataset.fieldValidatorKind === "password"
    )
    if (password && input.value !== password.value) {
      this.flag(input, { message: "Passwords don't match", severity: "error" })
    } else {
      this.clear(input)
    }
  }

  // Score 0–4 from length and character-class variety.
  strengthScore(value) {
    if (!value) return 0
    let score = 0
    if (value.length >= 6)  score++
    if (value.length >= 10) score++
    if (/[a-z]/.test(value) && /[A-Z]/.test(value)) score++
    if (/\d/.test(value))   score++
    if (/[^A-Za-z0-9]/.test(value)) score++
    return Math.min(4, score)
  }

  updateMeter(input, score) {
    const group = input.closest(".form-group") || this.element
    const bar   = group.querySelector("[data-strength-bar]")
    const label = group.querySelector("[data-strength-label]")
    if (!bar && !label) return

    const levels = [
      { width: "0%",   color: "bg-gray-300",    text: "" },
      { width: "25%",  color: "bg-red-500",     text: "Weak" },
      { width: "50%",  color: "bg-amber-500",   text: "Fair" },
      { width: "75%",  color: "bg-emerald-500", text: "Good" },
      { width: "100%", color: "bg-emerald-500", text: "Strong" }
    ]
    const level = levels[Math.max(0, Math.min(4, score))]

    if (bar) {
      bar.style.width = level.width
      bar.classList.remove("bg-gray-300", "bg-red-500", "bg-amber-500", "bg-emerald-500")
      bar.classList.add(level.color)
    }
    if (label) label.textContent = level.text
  }

  async run(input) {
    const value = input.value
    if (!value || !value.trim()) return this.clear(input)

    const kind = input.dataset.fieldValidatorKind || "text"
    let verdict
    try {
      const res = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ kind, value })
      })
      if (!res.ok) return // server still enforces; stay silent on a hiccup
      verdict = await res.json()
    } catch (_e) {
      return // offline/aborted: never block on a feedback-only call
    }

    verdict.ok ? this.clear(input) : this.flag(input, verdict)
  }

  flag(input, { message, severity }) {
    const error = severity !== "warning"

    input.classList.remove(
      "border-red-500", "focus:border-red-500", "focus:ring-red-500",
      "border-amber-500", "focus:border-amber-500", "focus:ring-amber-500"
    )
    input.classList.add(
      ...(error
        ? ["border-red-500", "focus:border-red-500", "focus:ring-red-500"]
        : ["border-amber-500", "focus:border-amber-500", "focus:ring-amber-500"])
    )

    const msg = this.messageFor(input)
    if (msg) {
      msg.textContent = message
      msg.classList.remove("hidden")
      msg.classList.toggle("text-amber-600", !error)     // warnings are amber
      msg.classList.toggle("dark:text-amber-400", !error)
    }

    error ? this.invalid.add(input) : this.invalid.delete(input)
    this.refreshSubmit()
  }

  clear(input) {
    input.classList.remove(
      "border-red-500", "focus:border-red-500", "focus:ring-red-500",
      "border-amber-500", "focus:border-amber-500", "focus:ring-amber-500"
    )

    const msg = this.messageFor(input)
    if (msg) {
      msg.textContent = ""
      msg.classList.add("hidden")
      msg.classList.remove("text-amber-600", "dark:text-amber-400")
    }

    this.invalid.delete(input)
    this.refreshSubmit()
  }

  refreshSubmit() {
    const disabled = this.invalid.size > 0
    this.submitTargets.forEach((btn) => {
      btn.disabled = disabled
      btn.classList.toggle("opacity-50", disabled)
      btn.classList.toggle("cursor-not-allowed", disabled)
    })
  }

  messageFor(input) {
    const group = input.closest(".form-group") || this.element
    return group.querySelector(".form-error")
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
