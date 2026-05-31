import { Controller } from "@hotwired/stimulus"

// Moves a lime radial-gradient glow to follow the cursor across the element.
// Attach to each bento tile:
//   data-controller="spotlight"
//   data-action="pointermove->spotlight#move pointerleave->spotlight#leave"
// The glow itself lives in the `.bento-tile::before` rule, positioned by the
// --mx / --my custom properties we set here. Skipped for reduced-motion users.
export default class extends Controller {
  connect() {
    this.reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  move(event) {
    if (this.reduced) return
    const rect = this.element.getBoundingClientRect()
    this.element.style.setProperty("--mx", `${event.clientX - rect.left}px`)
    this.element.style.setProperty("--my", `${event.clientY - rect.top}px`)
  }

  leave() {
    this.element.style.removeProperty("--mx")
    this.element.style.removeProperty("--my")
  }
}
