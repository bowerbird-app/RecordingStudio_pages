import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["gated", "colour"]

  connect() {
    this.onChange = this.sync.bind(this)
    this.onColourInput = this.captureColour.bind(this)
    this.layoutSelect?.addEventListener("change", this.onChange)
    this.presetSelect?.addEventListener("change", this.onChange)
    this.imageInput?.addEventListener("input", this.onChange)
    this.imageInput?.addEventListener("change", this.onChange)
    this.element.addEventListener("input", this.onColourInput)
    this.sync()
  }

  disconnect() {
    this.layoutSelect?.removeEventListener("change", this.onChange)
    this.presetSelect?.removeEventListener("change", this.onChange)
    this.imageInput?.removeEventListener("input", this.onChange)
    this.imageInput?.removeEventListener("change", this.onChange)
    this.element.removeEventListener("input", this.onColourInput)
  }

  captureColour(event) {
    if (event.target?.type !== "color") return

    const wrap = event.target.closest("[data-recording-studio-pages--style-fields-target='colour']")
    if (!wrap || !this.colourTargets.includes(wrap)) return

    const hidden = wrap.querySelector("input[data-colour-value]")
    if (hidden) hidden.value = event.target.value
  }

  sync() {
    const variant = this.layoutSelect?.value || ""
    const hasImage = Boolean(this.imageInput?.value)
    this.gatedTargets.forEach((field) => {
      const neededVariant = field.dataset.showWhenVariant
      const needsImage = field.dataset.showWhenImage === "true"
      let visible = true
      if (neededVariant) visible = variant === neededVariant
      if (visible && needsImage) visible = hasImage
      field.hidden = !visible
    })
    this.updateColourPreviews()
  }

  updateColourPreviews() {
    this.colourTargets.forEach((wrap) => {
      const hidden = wrap.querySelector("input[data-colour-value]")
      if (hidden?.value) return

      const input = wrap.querySelector("input[type='color']")
      const swatch = wrap.querySelector("[data-flat-pack--color-swatch-target='swatch']")
      const next = this.previewFor(wrap.dataset.colourKind)
      if (input) input.value = next
      if (swatch) swatch.style.backgroundColor = next
    })
  }

  previewFor(kind) {
    const variant = this.layoutSelect?.value || ""
    const preset = this.presetSelect?.value || "dark"
    if (kind === "title_color") {
      if (variant === "fullscreen_image") return preset === "light" ? "#222222" : "#ffffff"
      return "#171717"
    }

    if (variant === "fullscreen_image") return preset === "light" ? "#555555" : "#cccccc"
    return "#6b7280"
  }

  get layoutSelect() {
    return this.element.querySelector('select[name="section[settings][variant]"]')
  }

  get presetSelect() {
    return this.element.querySelector('select[name="section[settings][background]"]')
  }

  get imageInput() {
    return this.element.querySelector('input[name="section[content][image]"]')
  }
}
