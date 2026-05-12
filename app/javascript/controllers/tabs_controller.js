import { Controller } from "@hotwired/stimulus"

// Vertical / horizontal tab switcher. Clicking [data-action="tabs#show"] on a
// [data-tabs-target="tab"] reveals the matching [data-tabs-target="panel"] by
// matching their data-key attributes.
export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    const active = this.tabTargets.find(t => t.classList.contains("active")) || this.tabTargets[0]
    if (active) this.#activate(active.dataset.key)
  }

  show(event) {
    const key = event.currentTarget.dataset.key
    this.#activate(key)
  }

  #activate(key) {
    this.tabTargets.forEach(t => t.classList.toggle("active", t.dataset.key === key))
    this.panelTargets.forEach(p => p.classList.toggle("hidden", p.dataset.key !== key))
  }
}
