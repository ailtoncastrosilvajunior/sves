import { Controller } from "@hotwired/stimulus"

const MIME_SERVO_ID = "application/x-sves-servo-id"
const MOVE_TO_CANCEL_PENDING = 26
const LONG_PRESS_MS = 420

// Desktop largo (lg): arrastar até a zona tracejada. Telemóvel: multi-selecção ao tocar + «Adicionar seleccionados (n)», sem zona de largar.
export default class extends Controller {
  static targets = ["form", "principals", "pool", "dropzone", "touchBtn", "touchBtnLabel"]

  connect () {
    this.draggingLi = null
    this.selectionOrder = []
    this.suppressClickPickUntil = 0

    this.touchPending = null
    this.touchDragging = false
    this.touchPointerId = null
    this.touchServoLi = null

    this._boundMove = (e) => this.touchMoveWindow(e)
    this._boundUp = (e) => this.touchEndWindow(e)
    this._boundCancel = (e) => this.touchEndWindow(e)

    window.addEventListener("pointermove", this._boundMove, { passive: false })
    window.addEventListener("pointerup", this._boundUp)
    window.addEventListener("pointercancel", this._boundCancel)

    if (this.hasPoolTarget) {
      this._boundDown = (e) => this.touchStartPool(e)
      this.poolTarget.addEventListener("pointerdown", this._boundDown)
    }

    this.syncPrincipalsField()
    this.syncTouchUi()
  }

  disconnect () {
    window.removeEventListener("pointermove", this._boundMove)
    window.removeEventListener("pointerup", this._boundUp)
    window.removeEventListener("pointercancel", this._boundCancel)
    if (this.hasPoolTarget && this._boundDown) {
      this.poolTarget.removeEventListener("pointerdown", this._boundDown)
    }
    this.clearTouchLongPressTimer()
    this.touchReset(false)
  }

  dragstart (event) {
    const li = event.target.closest("[data-servo-id]")
    if (!li || !this.poolTarget.contains(li)) return

    const id = li.dataset.servoId

    event.dataTransfer.setData(MIME_SERVO_ID, id)
    event.dataTransfer.setData("text/plain", id)

    event.dataTransfer.effectAllowed = "copy"
    li.classList.add("opacity-60")
    li.classList.add("ring-2", "ring-stone-700")
    this.draggingLi = li
  }

  dragend () {
    if (this.draggingLi) {
      this.draggingLi.classList.remove("opacity-60", "ring-2", "ring-stone-700")
      this.draggingLi = null
    }
    this.unhighlightDropzone()
  }

  dragover (event) {
    if (!this.dropzoneInteractive()) return
    event.preventDefault()
    event.dataTransfer.dropEffect = "copy"

    this.highlightDropzone()
  }

  dragleave (event) {
    if (!this.dropzoneInteractive() || !this.hasDropzoneTarget) return

    if (!this.dropzoneTarget.contains(event.relatedTarget)) this.unhighlightDropzone()
  }

  drop (event) {
    if (!this.dropzoneInteractive()) return

    event.preventDefault()
    this.unhighlightDropzone()

    const id =
      event.dataTransfer.getData(MIME_SERVO_ID) ||
      event.dataTransfer.getData("text/plain")
    if (id) this.submitSingleFromDrag(id)
  }

  pick (event) {
    if (performance.now() < this.suppressClickPickUntil) return

    const li = event.target.closest("[data-servo-id]")
    if (!li || !this.poolTarget.contains(li)) return

    const id = li.dataset.servoId
    if (!id) return

    this.toggleServoSelection(li, id)
    this.syncPrincipalsField()
    this.syncTouchUi()
  }

  toggleServoSelection (li, id) {
    const i = this.selectionOrder.indexOf(id)

    if (i >= 0) {
      this.selectionOrder.splice(i, 1)
      li.classList.remove("ring-2", "ring-stone-800", "bg-stone-100")
      li.classList.remove("ring-offset-2", "ring-offset-white")
      li.setAttribute("aria-checked", "false")
      return
    }

    this.selectionOrder.push(id)
    li.classList.add("ring-2", "ring-stone-800", "bg-stone-100", "ring-offset-2", "ring-offset-white")
    li.setAttribute("aria-checked", "true")
  }

  confirmSelection (event) {
    event.preventDefault()
    if (this.selectionOrder.length === 0) return

    this.principalsTarget.value = this.selectionOrder.join(",")

    const btn = this.formTarget.querySelector('[data-behavior="lote-submit"]')
    btn?.click()
  }

  highlightDropzone () {
    if (!this.dropzoneInteractive() || !this.hasDropzoneTarget) return

    this.dropzoneTarget.classList.add(
      "border-amber-400",
      "bg-amber-50/60",
      "ring-2",
      "ring-amber-300/70",
    )
  }

  unhighlightDropzone () {
    if (!this.hasDropzoneTarget) return

    this.dropzoneTarget.classList.remove(
      "border-amber-400",
      "bg-amber-50/60",
      "ring-2",
      "ring-amber-300/70",
    )
  }

  syncPrincipalsField () {
    this.principalsTarget.value = this.selectionOrder.join(",")
  }

  syncTouchUi () {
    if (!this.hasTouchBtnTarget) return

    const n = this.selectionOrder.length
    this.touchBtnTarget.disabled = n === 0

    if (this.hasTouchBtnLabelTarget) {
      this.touchBtnLabelTarget.textContent =
        n === 0 ? "Adicionar seleccionados" : `Adicionar seleccionados (${n})`
    }
  }

  submitSingleFromDrag (servoId) {
    if (!servoId) return
    this.principalsTarget.value = String(servoId)

    const btn = this.formTarget.querySelector('[data-behavior="lote-submit"]')
    btn?.click()
  }

  dropzoneInteractive () {
    return this.hasDropzoneTarget &&
      !!this.dropzoneTarget.offsetParent
  }

  // --- Arrastar táctil (só onde a zona existe e está visível, i.e. ecrã ≥ lg)

  touchStartPool (event) {
    if (event.pointerType !== "touch" || !this.dropzoneInteractive()) return

    const li = event.target.closest("[data-servo-id]")
    if (!li || !this.poolTarget.contains(li)) return

    this.clearTouchLongPressTimer()

    const startX = event.clientX
    const startY = event.clientY

    const pointerId = event.pointerId
    const servoId = li.dataset.servoId

    this.touchPending = {
      pointerId,
      servoId,
      startX,
      startY,
      li,

      timerId: window.setTimeout(() => {
        if (!this.touchPending || this.touchPending.pointerId !== pointerId) return
        this.beginTouchDrag(pointerId, li, servoId)
      }, LONG_PRESS_MS),
    }
  }

  touchMoveWindow (event) {
    if (this.touchPending && event.pointerId === this.touchPending.pointerId) {
      const dx = event.clientX - this.touchPending.startX
      const dy = event.clientY - this.touchPending.startY
      if (Math.hypot(dx, dy) > MOVE_TO_CANCEL_PENDING) {
        this.clearTouchLongPressTimer()

        if (!this.touchDragging) this.touchPending = null
      }
    }

    if (!this.touchDragging || event.pointerId !== this.touchPointerId) return
    event.preventDefault()
    const li = this.touchServoLi
    li?.classList.add("opacity-70", "ring-2", "ring-teal-600")
    if (this.dropzoneInteractive()) {
      this.highlightDropzone()

      this.maybeScrollDropIntoView()
    }
  }

  touchEndWindow (event) {
    if (!this.touchPending &&
        !(this.touchDragging && event.pointerId === this.touchPointerId)) {
      return
    }

    if (this.touchPending && event.pointerId === this.touchPending.pointerId) {
      this.clearTouchLongPressTimer()

      this.touchPending = null
    }

    if (this.touchDragging && event.pointerId === this.touchPointerId) {
      const li = this.touchServoLi
      const id = li?.dataset?.servoId

      li?.classList.remove("opacity-70", "ring-2", "ring-teal-600")
      try {
        li?.releasePointerCapture(this.touchPointerId)
      } catch (_) {
        // noop
      }

      if (
        id &&
        this.dropzoneInteractive() &&
        this.pointInDropzone(event.clientX, event.clientY)
      ) {
        this.suppressClickPickUntil = performance.now() + 700
        this.submitSingleFromDrag(id)
      }

      this.unhighlightDropzone()
      this.touchReset(true)
    }
  }

  beginTouchDrag (pointerId, li, servoId) {
    if (!servoId || !this.dropzoneInteractive()) return

    this.clearTouchLongPressTimer()
    this.touchPending = null

    this.touchDragging = true

    this.touchPointerId = pointerId
    this.touchServoLi = li

    try {
      li.setPointerCapture(pointerId)
    } catch (_) {
      // noop
    }

    li.classList.add("opacity-70", "ring-2", "ring-teal-600")
    if (this.dropzoneInteractive()) {
      this.highlightDropzone()
      this.maybeScrollDropIntoView()
    }

    navigator.vibrate?.(18)
    this.suppressClickPickUntil = performance.now() + 400
  }

  touchReset (keepTimersCleared = false) {
    this.touchDragging = false
    this.touchPointerId = null
    if (this.touchServoLi) {
      this.touchServoLi.classList.remove("opacity-70", "ring-2", "ring-teal-600")
    }

    this.touchServoLi = null
    if (!keepTimersCleared) this.clearTouchLongPressTimer()
    else this.touchPending = null
  }

  clearTouchLongPressTimer () {
    if (!this.touchPending) return
    if (this.touchPending.timerId) {
      window.clearTimeout(this.touchPending.timerId)
      delete this.touchPending.timerId
    }

    if (!this.touchDragging) this.touchPending = null
  }

  pointInDropzone (clientX, clientY) {
    const rect = this.dropzoneTarget.getBoundingClientRect()
    if (
      rect.width === 0 ||
      rect.height === 0
    ) return false

    return (
      clientX >= rect.left &&
      clientX <= rect.right &&
      clientY >= rect.top &&
      clientY <= rect.bottom
    )
  }

  maybeScrollDropIntoView () {
    if (!this.hasDropzoneTarget) return

    const rect = this.dropzoneTarget.getBoundingClientRect()
    const pad = 12
    if (rect.bottom > window.innerHeight - pad) {
      this.dropzoneTarget.scrollIntoView({ behavior: "smooth", block: "nearest" })
    }

    if (rect.top < pad) {
      this.dropzoneTarget.scrollIntoView({ behavior: "smooth", block: "start" })
    }
  }
}
