import { Controller } from "@hotwired/stimulus"

// Drives the multi-file XHR upload on /videos/new. Captures lastModified
// timestamps into a hidden field, posts the form via XHR so the progress bar
// can fill smoothly, then redirects on success.
export default class extends Controller {
  static targets = ["file", "recordedAt", "form", "progress", "bar", "status", "submit"]
  static values = {
    uploading: String,
    success: String,
    failure: String,
    fallbackUrl: String
  }

  connect() {
    this.boundFiles = this.captureRecordedAts.bind(this)
    this.boundSubmit = this.submit.bind(this)
    this.fileTarget.addEventListener("change", this.boundFiles)
    this.formTarget.addEventListener("submit", this.boundSubmit)
  }

  disconnect() {
    this.fileTarget.removeEventListener("change", this.boundFiles)
    this.formTarget.removeEventListener("submit", this.boundSubmit)
  }

  captureRecordedAts() {
    const files = this.fileTarget.files
    const dates = []
    for (let i = 0; i < files.length; i++) {
      const lm = files[i].lastModified
      dates.push(lm ? new Date(lm).toISOString() : null)
    }
    this.recordedAtTarget.value = JSON.stringify(dates)
  }

  submit(event) {
    event.preventDefault()
    const form = this.formTarget
    const data = new FormData(form)
    const xhr = new XMLHttpRequest()
    const count = this.fileTarget.files.length

    this.progressTarget.classList.remove("hidden")
    this.submitTarget.disabled = true
    this.barTarget.style.width = "0%"
    this.barTarget.textContent = "0%"
    this.barTarget.classList.remove("bg-danger", "bg-ok")
    this.barTarget.classList.add("bg-accent")
    this.statusTarget.textContent = `${this.uploadingValue} (${count})...`

    xhr.upload.addEventListener("progress", (e) => {
      if (!e.lengthComputable) return
      const percent = Math.round((e.loaded / e.total) * 100)
      this.barTarget.style.width = percent + "%"
      this.barTarget.textContent = percent + "%"
    })

    xhr.addEventListener("load", () => {
      let response = {}
      try { response = JSON.parse(xhr.responseText) } catch (_) {}

      if (xhr.status >= 200 && xhr.status < 300) {
        this.barTarget.classList.remove("bg-accent")
        this.barTarget.classList.add("bg-ok")
        this.barTarget.style.width = "100%"
        this.barTarget.textContent = "100%"
        this.statusTarget.textContent = response.notice || this.successValue
        setTimeout(() => {
          window.location.href = response.redirect_url || this.fallbackUrlValue
        }, 800)
      } else {
        this.barTarget.classList.remove("bg-accent")
        this.barTarget.classList.add("bg-danger")
        this.statusTarget.textContent = (response.errors || []).join("; ") || this.failureValue
        this.submitTarget.disabled = false
      }
    })

    xhr.addEventListener("error", () => {
      this.barTarget.classList.remove("bg-accent")
      this.barTarget.classList.add("bg-danger")
      this.statusTarget.textContent = this.failureValue
      this.submitTarget.disabled = false
    })

    xhr.open("POST", form.action)
    const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
    if (token) xhr.setRequestHeader("X-CSRF-Token", token)
    xhr.setRequestHeader("Accept", "application/json")
    xhr.send(data)
  }
}
