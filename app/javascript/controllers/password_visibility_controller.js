import { Controller } from "@hotwired/stimulus"

// Alterna type=password/text; ícones e aria-label em pt-BR vêm dos data-*-value no HTML.
export default class extends Controller {
  static targets = ["input", "iconShow", "iconHide", "button"]
  static values = {
    showLabel: String,
    hideLabel: String,
  }

  connect () {
    this._syncAll()
  }

  toggle (event) {
    event.preventDefault()
    const input = this.inputTarget
    input.type = input.type === "password" ? "text" : "password"
    this._syncAll()
  }

  _syncAll () {
    const masked = this.inputTarget.type === "password"
    if (this.hasIconShowTarget && this.hasIconHideTarget) {
      this.iconShowTarget.classList.toggle("hidden", !masked)
      this.iconHideTarget.classList.toggle("hidden", masked)
    }
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-pressed", masked ? "false" : "true")
      this.buttonTarget.setAttribute(
        "aria-label",
        masked ? this.showLabelValue : this.hideLabelValue,
      )
    }
  }
}
