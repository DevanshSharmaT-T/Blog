import { Controller } from "@hotwired/stimulus"

// Submits the form this controller is mounted on whenever a watched input fires.
// Use for select menus that should save immediately on change — no separate
// submit button.
//
//   <%= form_with ..., data: { controller: "auto-submit" } do |f| %>
//     <%= f.select :role, ..., data: { action: "change->auto-submit#submit" } %>
//   <% end %>
//
// requestSubmit() (not submit()) fires a real submit event so Turbo intercepts it.
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
