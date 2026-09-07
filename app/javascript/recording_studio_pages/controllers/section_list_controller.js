import { Controller } from "@hotwired/stimulus"

// Flatpack List orderable reorders the DOM. Persist lives here because Flatpack's
// orderable save still checks hasOrderablePathValue after the value was renamed
// to orderableUrl. Do not also set orderable_url on the list or a Flatpack fix
// would double-PATCH.
export default class extends Controller {
  static values = {
    url: String
  }

  connect() {
    this.preventMenuDrag = this.preventMenuDrag.bind(this)
    this.reloadList = this.reloadList.bind(this)
    this.element.addEventListener("dragstart", this.preventMenuDrag, true)
    this.element.addEventListener("list:error", this.reloadList)
  }

  disconnect() {
    this.element.removeEventListener("dragstart", this.preventMenuDrag, true)
    this.element.removeEventListener("list:error", this.reloadList)
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

    let body = {}
    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content || "",
          Accept: "application/json"
        },
        body: payload.toString()
      })
      try {
        body = await response.json()
      } catch (_error) {
        body = {}
      }

      if (!response.ok || body.ok === false) {
        this.element.dispatchEvent(new CustomEvent("list:error", { detail: body, bubbles: true }))
      }
    } catch (_error) {
      this.element.dispatchEvent(new CustomEvent("list:error", {
        detail: { error: "The new order did not save." },
        bubbles: true
      }))
    }
  }

  reloadList() {
    const frame = this.element.closest("turbo-frame")
    if (frame?.id && window.Turbo) {
      window.Turbo.visit(window.location.href, { frame: frame.id, action: "replace" })
      return
    }

    window.location.reload()
  }
}
