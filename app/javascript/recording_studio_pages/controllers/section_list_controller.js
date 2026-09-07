import { Controller } from "@hotwired/stimulus"

// Flatpack List orderable reorders the DOM, then this persists via RS Orderable.
// Also blocks drag when the row menu is the target so More stays clickable.
export default class extends Controller {
  static values = {
    url: String
  }

  connect() {
    this.preventMenuDrag = this.preventMenuDrag.bind(this)
    this.element.addEventListener("dragstart", this.preventMenuDrag, true)
  }

  disconnect() {
    this.element.removeEventListener("dragstart", this.preventMenuDrag, true)
  }

  preventMenuDrag(event) {
    if (event.target.closest("[data-section-row-menu]")) {
      event.preventDefault()
      event.stopPropagation()
    }
  }

  async persist(event) {
    const id = event.detail?.id
    const position = event.detail?.position
    if (!id || !position || !this.hasUrlValue) return

    const payload = new URLSearchParams()
    payload.set("moving_recording_id", id)
    payload.set("target_position", String(position))

    await fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content || "",
        Accept: "application/json"
      },
      body: payload.toString()
    })
  }
}
