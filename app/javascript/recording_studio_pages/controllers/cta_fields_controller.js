import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this.selectElement = this.element.querySelector("select")
    this.onChange = this.select.bind(this)
    this.selectElement?.addEventListener("change", this.onChange)
    this.select()
  }

  disconnect() {
    this.selectElement?.removeEventListener("change", this.onChange)
  }

  select() {
    const type = this.selectElement?.value || ""
    this.panelTargets.forEach((panel) => {
      const active = panel.dataset.ctaKey === type
      panel.hidden = !active
      panel.querySelectorAll("input, textarea, select").forEach((field) => {
        field.disabled = !active
      })
    })
  }
}
