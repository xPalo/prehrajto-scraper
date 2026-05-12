import { Controller } from "@hotwired/stimulus"

// Typeahead filter for any list of [data-client-filter-target="row"] elements.
// Uses Unicode normalization so Slovak diacritics match their plain forms.
const COMBINING_MARKS = /[̀-ͯ]/g

export default class extends Controller {
  static targets = ["input", "row", "empty"]

  connect() {
    this.filter()
  }

  filter() {
    const query = this.#normalize(this.inputTarget.value.trim())
    let visible = 0
    this.rowTargets.forEach((row) => {
      const haystack = this.#normalize(row.textContent)
      const matches = query === "" || haystack.includes(query)
      row.classList.toggle("hidden", !matches)
      if (matches) visible++
    })
    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", visible !== 0)
    }
  }

  #normalize(str) {
    return str.normalize("NFD").replace(COMBINING_MARKS, "").toLowerCase()
  }
}
