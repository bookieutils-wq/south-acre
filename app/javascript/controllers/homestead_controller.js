import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "plot" ]

  connect() {
    this.startedAt = Date.now()
    this.dueReloads = 0
    this.paint()
    this.arm()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  arm() {
    const delay = Math.max(250, Math.min(this.msUntilNext(), 15000))
    this.timer = setTimeout(() => this.wake(), delay)
  }

  wake() {
    this.paint()
    if (this.shouldReload() && !this.typing()) {
      this.reload()
      return
    }
    this.arm()
  }

  paint() {
    this.plotTargets.forEach((plot) => {
      if (plot.dataset.state !== "growing") return

      const planted = Number(plot.dataset.plantedAt)
      const ready = Number(plot.dataset.readyAt)
      const span = Math.max(ready - planted, 1)
      const progress = Math.min(Math.max((Date.now() - planted) / span, 0), 1)
      plot.dataset.stage = progress >= 1 ? "ripe" : this.stageFor(progress)

      const meter = plot.querySelector("[data-meter]")
      if (meter) {
        meter.style.width = `${progress * 100}%`
        meter.parentElement?.setAttribute("aria-valuenow", String(Math.round(progress * 100)))
      }

      const label = plot.querySelector("[data-remaining]")
      if (label) {
        const left = Math.max(0, Math.ceil((ready - Date.now()) / 1000))
        label.textContent = left === 0 ? "Ready" : this.format(left)
      }
    })

    this.element.dispatchEvent(new CustomEvent("homestead:tick", { bubbles: true }))
  }

  shouldReload() {
    return this.cropDue() || this.pulseDue()
  }

  cropDue() {
    return this.plotTargets.some((plot) => {
      return plot.dataset.state === "growing" && Date.now() >= Number(plot.dataset.readyAt) + 400
    })
  }

  pulseDue() {
    return Date.now() - this.startedAt >= 60000
  }

  typing() {
    const active = document.activeElement
    return this.element.contains(active) && active.matches("input, select, textarea")
  }

  reload() {
    if (this.reloading) return
    this.reloading = true

    const frame = this.element.closest("turbo-frame")
    if (!frame) {
      this.reloading = false
      return
    }

    frame.addEventListener("turbo:frame-load", () => {
      this.reloading = false
    }, { once: true })

    if (typeof frame.reload === "function") frame.reload()
    else frame.src = window.location.pathname + window.location.search
  }

  msUntilNext() {
    if (this.cropDue()) return 300

    const marks = [ Date.now() + 60000 ]
    this.plotTargets.forEach((plot) => {
      if (plot.dataset.state !== "growing") return
      const planted = Number(plot.dataset.plantedAt)
      const ready = Number(plot.dataset.readyAt)
      const span = ready - planted
      ;[ 0.25, 0.55, 0.85, 1 ].forEach((mark) => {
        const at = planted + span * mark
        if (at > Date.now() + 200) marks.push(at)
      })
    })
    return Math.min(...marks) - Date.now()
  }

  stageFor(progress) {
    if (progress >= 0.85) return "ripe"
    if (progress >= 0.55) return "leaf"
    if (progress >= 0.25) return "sprout"
    return "seed"
  }

  format(total) {
    const hours = Math.floor(total / 3600)
    const minutes = Math.floor((total % 3600) / 60)
    const secs = total % 60
    if (hours > 0) return `${hours}h ${minutes}m`
    if (minutes > 0) return `${minutes}m ${String(secs).padStart(2, "0")}s`
    return `${secs}s`
  }
}
