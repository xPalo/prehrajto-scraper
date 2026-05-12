import { Controller } from "@hotwired/stimulus"

// Drives the prehrajto search box. Enter (or the icon button) submits via
// full-page redirect to ?search_url=/hledej/<query>, matching HomeController#prehrajto.
export default class extends Controller {
  static targets = ["input"]

  submit(event) {
    event?.preventDefault?.()
    const value = this.inputTarget.value.trim()
    if (!value) return
    const url = new URL(window.location.href)
    url.searchParams.set("search_url", `/hledej/${value}`)
    url.searchParams.delete("movie_url")
    url.searchParams.delete("movie_title")
    url.searchParams.delete("movie_duration")
    url.searchParams.delete("movie_size")
    window.location.href = url.toString()
  }

  keydown(event) {
    if (event.key === "Enter") this.submit(event)
  }
}
