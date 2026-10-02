import { Controller } from "@hotwired/stimulus"
import { FieldScene } from "field/scene"

export default class extends Controller {
  static targets = [ "canvas", "plot", "hint", "panel" ]
  static values = {
    weather: { type: String, default: "clear" },
    selected: { type: String, default: "" }
  }

  connect() {
    this.bootScene()
  }

  disconnect() {
    this.teardownScene()
  }

  canvasTargetConnected() {
    if (!this.scene) this.bootScene()
  }

  canvasTargetDisconnected() {
    this.teardownScene()
  }

  bootScene() {
    if (this.scene || !this.hasCanvasTarget) return

    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.scene = new FieldScene(this.canvasTarget, {
      weather: this.weatherValue,
      reducedMotion: this.reducedMotion
    })
    this.syncScene()
    this.restoreSelection()
    this.scene.start()
    this.boundResize = () => this.scene?.resize()
    window.addEventListener("resize", this.boundResize)
  }

  teardownScene() {
    if (this.boundResize) {
      window.removeEventListener("resize", this.boundResize)
      this.boundResize = null
    }
    this.scene?.dispose()
    this.scene = null
  }

  weatherValueChanged() {
    this.scene?.setWeather(this.weatherValue)
  }

  pick(event) {
    if (!this.scene || this.pointerMoved) return
    const id = this.scene.pick(event.clientX, event.clientY)
    if (!id) return
    this.select(id, { reveal: true })
  }

  notePointerDown(event) {
    if (event.button !== 0 && event.pointerType === "mouse") return
    this.pointerOrigin = { x: event.clientX, y: event.clientY }
    this.pointerMoved = false
  }

  notePointerMove(event) {
    if (!this.pointerOrigin) return
    const dx = event.clientX - this.pointerOrigin.x
    const dy = event.clientY - this.pointerOrigin.y
    if ((dx * dx) + (dy * dy) > 36) this.pointerMoved = true
  }

  notePointerUp() {
    this.pointerOrigin = null
  }

  zoomIn(event) {
    event.preventDefault()
    this.scene?.zoomIn()
  }

  zoomOut(event) {
    event.preventDefault()
    this.scene?.zoomOut()
  }

  resetView(event) {
    event.preventDefault()
    this.scene?.resetView()
  }

  selectPlot(event) {
    const plot = event.currentTarget
    if (plot?.dataset.plotId) this.select(plot.dataset.plotId, { reveal: true })
  }

  select(id, { reveal = false } = {}) {
    const selectedId = String(id)
    this.selectedValue = selectedId
    this.scene?.select(selectedId)

    let selectedPlot = null
    this.plotTargets.forEach((plot) => {
      const match = plot.dataset.plotId === selectedId
      plot.hidden = !match
      plot.classList.toggle("is-selected", match)
      if (match) selectedPlot = plot
    })

    if (this.hasHintTarget) this.hintTarget.hidden = true

    try { sessionStorage.setItem("homestead-selected-plot", selectedId) } catch (_) { /* ignore */ }

    if (reveal && selectedPlot) {
      const target = this.hasPanelTarget ? this.panelTarget : selectedPlot
      target.scrollIntoView({ block: "nearest", inline: "nearest", behavior: this.reducedMotion ? "auto" : "smooth" })
    }
  }

  restoreSelection() {
    let saved = this.selectedValue
    try { saved = saved || sessionStorage.getItem("homestead-selected-plot") || "" } catch (_) { /* ignore */ }

    const available = this.plotTargets.map((plot) => plot.dataset.plotId)
    const pick = available.includes(String(saved))
      ? String(saved)
      : (this.plotTargets.find((plot) => plot.dataset.state === "ready")?.dataset.plotId || available[0])

    if (pick) this.select(pick)
  }

  syncScene() {
    if (!this.scene) return
    const plots = this.plotTargets.map((el) => ({
      id: el.dataset.plotId,
      position: Number(el.dataset.position || 0),
      state: el.dataset.state,
      crop: el.dataset.crop || null,
      plantedAt: el.dataset.plantedAt ? Number(el.dataset.plantedAt) : null,
      readyAt: el.dataset.readyAt ? Number(el.dataset.readyAt) : null
    }))
    this.scene.syncPlots(plots)
    if (this.selectedValue) this.scene.select(this.selectedValue)
  }

  refreshGrowth() {
    this.syncScene()
  }
}
