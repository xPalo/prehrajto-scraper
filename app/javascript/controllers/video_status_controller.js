import { Controller } from "@hotwired/stimulus"

// Polls /videos/:id.json every 5 s while a video is pending or processing.
// Stops once the server reports a terminal state (completed / failed) and
// rewrites the action region with the appropriate UI.
export default class extends Controller {
  static targets = ["status", "actions"]
  static values = {
    url: String,
    statusCompleted: String,
    statusProcessing: String,
    statusFailed: String,
    downloadLabel: String,
    errorLabel: String,
    unknownError: String
  }

  connect() {
    this.timer = setInterval(() => this.poll(), 5000)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
  }

  async poll() {
    let data
    try {
      const res = await fetch(this.urlValue, { headers: { "Accept": "application/json" } })
      if (!res.ok) return
      data = await res.json()
    } catch (_) {
      return
    }
    if (!data) return

    if (data.status === "completed") {
      clearInterval(this.timer)
      this.#setStatus(this.statusCompletedValue, "badge-ok")
      const link = document.createElement("a")
      link.href = data.download_url
      link.className = "btn-primary"
      link.innerHTML = `${this.downloadLabelValue}`
      this.actionsTarget.replaceChildren(link)
    } else if (data.status === "failed") {
      clearInterval(this.timer)
      this.#setStatus(this.statusFailedValue, "badge-danger")
      const msg = data.error_message || this.unknownErrorValue
      this.actionsTarget.innerHTML =
        `<span class="text-danger text-sm"><strong>${this.errorLabelValue}:</strong> ${msg}</span>`
    } else if (data.status === "processing") {
      this.#setStatus(this.statusProcessingValue, "badge-warn")
    }
  }

  #setStatus(label, klass) {
    this.statusTarget.className = "badge " + klass
    this.statusTarget.textContent = label
  }
}
