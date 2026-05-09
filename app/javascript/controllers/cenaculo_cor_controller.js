import { Controller } from "@hotwired/stimulus"

// Sincroniza campo hex do cenáculo com o «color picker» nativo do SO e swatches pré-definidas.
export default class extends Controller {
  static targets = ["hex", "picker"]

  connect () {
    this.syncPickerFromHex()
  }

  choose (event) {
    let hex = event.params?.hex

    // compat: algumas versões usam apenas o DOM
    if (!hex && event.currentTarget) {
      hex = event.currentTarget.getAttribute("data-cenaculo-cor-hex-param")
    }

    if (!hex) return

    this.hexTarget.value = hex
    this.syncPickerFromHex()
  }

  pickerChanged () {
    this.hexTarget.value = this.pickerTarget.value
  }

  limparCor () {
    this.hexTarget.value = ""
    this.pickerTarget.value = "#cccccc"
  }

  syncPickerFromHex () {
    const raw = (this.hexTarget.value || "").trim()
    if (raw === "") {
      // Visível apenas — não há name no picker, campo enviado fica em branco
      this.pickerTarget.value = "#cccccc"
      return
    }

    const expanded = this.expandShortHex(raw)
    if (/^#[0-9a-f]{6}$/i.test(expanded)) {
      this.pickerTarget.value = expanded.toLowerCase()
    }
  }

  expandShortHex (hex) {
    const h = hex.trim()
    if (/^#[0-9a-f]{3}$/i.test(h)) {
      const r = h[1] + h[1]
      const g = h[2] + h[2]
      const b = h[3] + h[3]
      return `#${r}${g}${b}`
    }

    return h
  }
}
