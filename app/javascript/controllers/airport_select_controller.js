import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

// Boots Tom Select on the airport selects of the watchdog form and toggles
// the to_airport / to_country fields so only one is visible at a time.
export default class extends Controller {
  static targets = ["from", "to", "country", "toWrapper", "countryWrapper"]

  connect() {
    const opts = { allowEmptyOption: true, plugins: ["clear_button"] }
    this.fromTs = new TomSelect(this.fromTarget, opts)
    this.toTs = new TomSelect(this.toTarget, opts)

    this.update = this.update.bind(this)
    this.toTs.on("change", this.update)
    this.countryTarget.addEventListener("input", this.update)

    this.update()
  }

  disconnect() {
    this.fromTs?.destroy()
    this.toTs?.destroy()
    this.countryTarget?.removeEventListener("input", this.update)
  }

  update() {
    const hasAirport = this.toTs.getValue() !== ""
    const hasCountry = this.countryTarget.value.trim() !== ""
    this.countryWrapperTarget.classList.toggle("hidden", hasAirport)
    this.toWrapperTarget.classList.toggle("hidden", hasCountry)
  }
}
