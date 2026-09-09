import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "empty", "remove"]

  selected(event) {
    const attachment = event.detail?.attachment
    if (!attachment?.id) return

    this.inputTarget.value = attachment.id
    const previewUrl = attachment.thumbnail_url || attachment.insert_url || ""
    if (this.hasPreviewTarget && previewUrl) {
      this.previewTarget.src = previewUrl
      this.previewTarget.classList.remove("hidden")
    }
    if (this.hasEmptyTarget) this.emptyTarget.classList.add("hidden")
    if (this.hasRemoveTarget) this.removeTarget.hidden = false
  }

  clear(event) {
    event.preventDefault()
    this.inputTarget.value = ""
    if (this.hasPreviewTarget) {
      this.previewTarget.src = ""
      this.previewTarget.classList.add("hidden")
    }
    if (this.hasEmptyTarget) this.emptyTarget.classList.remove("hidden")
    if (this.hasRemoveTarget) this.removeTarget.hidden = true
  }
}
