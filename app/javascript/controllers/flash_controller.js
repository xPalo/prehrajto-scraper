import { Controller } from "@hotwired/stimulus"

// Auto-dismisses a flash element after a delay and supports manual close.
export default class extends Controller {
  static values = { delay: { type: Number, default: 6000 } }

  connect() {
    if (this.delayValue > 0) {
      this.timer = setTimeout(() => this.close(), this.delayValue)
    }
  }

  disconnect() {
    if (this.timer) clearTimeout(this.timer)
  }

  close() {
    this.element.classList.add("opacity-0", "translate-y-1")
    setTimeout(() => this.element.remove(), 200)
  }
}
