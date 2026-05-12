import { Controller } from "@hotwired/stimulus"

// Submits the page with ?order=<value> when a select changes.
export default class extends Controller {
  change(event) {
    const value = event.target.value
    const url = new URL(window.location.href)
    if (value) {
      url.searchParams.set("order", value)
    } else {
      url.searchParams.delete("order")
    }
    window.location.href = url.toString()
  }
}
