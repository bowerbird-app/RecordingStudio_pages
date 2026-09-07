import { Controller } from "@hotwired/stimulus"

// Flatpack List save runs when orderable_url is set. This controller only
// stops More-menu drags and reloads if that save fails.
export default class extends Controller {
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

  reloadList() {
    const frame = this.element.closest("turbo-frame")
    if (frame?.id && window.Turbo) {
      window.Turbo.visit(window.location.href, { frame: frame.id, action: "replace" })
      return
    }

    window.location.reload()
  }
}
