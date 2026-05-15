import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { src: String }

  connect() {
    if (!this.srcValue) return
    fetch(this.srcValue, { headers: { "Accept": "text/html" } })
      .then((response) => response.ok ? response.text() : "")
      .then((html) => { if (html) this.element.innerHTML = html })
      .catch(() => {})
  }
}
