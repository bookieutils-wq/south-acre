import * as THREE from "three"
import { OrbitControls } from "three/addons/controls/OrbitControls"

const BED = 1.55
const GAP = 0.35
const COLS = 3
const DEFAULT_CAMERA = { x: 0, y: 8.4, z: 9.2 }
const DEFAULT_TARGET = { x: 0, y: 0.2, z: 0.4 }
const CROP_COLORS = {
  radish: 0xc44536,
  lettuce: 0x6a9a3e,
  wheat: 0xd7a441,
  tomato: 0xd4533a,
  pumpkin: 0xe08a2a,
  apple: 0xb4333a
}

const SKY = {
  clear: [ 0xb9d4ef, 0xe8d6a8 ],
  rain: [ 0x6d8296, 0xa8b4bb ],
  dry: [ 0xd7b88a, 0xe8c98a ]
}

export class FieldScene {
  constructor(canvas, { weather = "clear", reducedMotion = false } = {}) {
    this.canvas = canvas
    this.weather = weather
    this.reducedMotion = reducedMotion
    this.beds = new Map()
    this.clock = new THREE.Clock()
    this.pointer = new THREE.Vector2()
    this.raycaster = new THREE.Raycaster()
    this.selectedId = null
    this.running = false

    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false })
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2))
    this.renderer.shadowMap.enabled = true
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap
    this.renderer.outputColorSpace = THREE.SRGBColorSpace

    this.scene = new THREE.Scene()
    this.camera = new THREE.PerspectiveCamera(42, 1, 0.1, 80)
    this.camera.position.set(DEFAULT_CAMERA.x, DEFAULT_CAMERA.y, DEFAULT_CAMERA.z)

    this.controls = new OrbitControls(this.camera, this.canvas)
    this.controls.target.set(DEFAULT_TARGET.x, DEFAULT_TARGET.y, DEFAULT_TARGET.z)
    this.controls.enableDamping = !reducedMotion
    this.controls.dampingFactor = 0.08
    this.controls.enablePan = true
    this.controls.screenSpacePanning = true
    this.controls.minDistance = 4
    this.controls.maxDistance = 22
    this.controls.minPolarAngle = 0.18
    this.controls.maxPolarAngle = Math.PI * 0.48
    this.controls.zoomSpeed = 0.9
    this.controls.rotateSpeed = 0.7
    this.controls.panSpeed = 0.6
    this.controls.update()

    this.buildWorld()
    this.setWeather(weather)
    this.resize()
  }

  buildWorld() {
    this.ground = new THREE.Mesh(
      new THREE.PlaneGeometry(28, 22),
      new THREE.MeshStandardMaterial({ color: 0x5f8a4a, roughness: 0.92 })
    )
    this.ground.rotation.x = -Math.PI / 2
    this.ground.receiveShadow = true
    this.scene.add(this.ground)

    const path = new THREE.Mesh(
      new THREE.PlaneGeometry(1.1, 16),
      new THREE.MeshStandardMaterial({ color: 0xc2a16a, roughness: 1 })
    )
    path.rotation.x = -Math.PI / 2
    path.position.set(-4.4, 0.01, 0.3)
    path.receiveShadow = true
    this.scene.add(path)

    const fenceMat = new THREE.MeshStandardMaterial({ color: 0x8b5a2b, roughness: 0.85 })
    ;[-1, 1].forEach((side) => {
      for (let i = -4; i <= 4; i += 1) {
        const post = new THREE.Mesh(new THREE.CylinderGeometry(0.06, 0.08, 1.1, 6), fenceMat)
        post.position.set(side * 6.4, 0.55, i * 1.4)
        post.castShadow = true
        this.scene.add(post)
      }
      const rail = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.08, 12), fenceMat)
      rail.position.set(side * 6.4, 0.75, 0)
      this.scene.add(rail)
    })

    const barn = new THREE.Group()
    const body = new THREE.Mesh(
      new THREE.BoxGeometry(3.4, 2.2, 2.6),
      new THREE.MeshStandardMaterial({ color: 0x8f3b2e, roughness: 0.8 })
    )
    body.position.y = 1.1
    body.castShadow = true
    body.receiveShadow = true
    barn.add(body)
    const roof = new THREE.Mesh(
      new THREE.ConeGeometry(2.5, 1.2, 4),
      new THREE.MeshStandardMaterial({ color: 0x4a2f22, roughness: 0.9 })
    )
    roof.position.y = 2.55
    roof.rotation.y = Math.PI / 4
    roof.castShadow = true
    barn.add(roof)
    barn.position.set(-5.8, 0, -5.8)
    this.scene.add(barn)

    this.hemi = new THREE.HemisphereLight(0xf2f0e4, 0x4d6a3a, 1.05)
    this.scene.add(this.hemi)

    this.sun = new THREE.DirectionalLight(0xfff1c9, 1.35)
    this.sun.position.set(6, 12, 4)
    this.sun.castShadow = true
    this.sun.shadow.mapSize.set(1024, 1024)
    this.sun.shadow.camera.left = -10
    this.sun.shadow.camera.right = 10
    this.sun.shadow.camera.top = 10
    this.sun.shadow.camera.bottom = -10
    this.scene.add(this.sun)

    this.fill = new THREE.DirectionalLight(0xb7d7ff, 0.35)
    this.fill.position.set(-5, 4, -3)
    this.scene.add(this.fill)

    this.rain = this.createRain()
    this.scene.add(this.rain)
  }

  createRain() {
    const count = 900
    const positions = new Float32Array(count * 3)
    for (let i = 0; i < count; i += 1) {
      positions[i * 3] = (Math.random() - 0.5) * 16
      positions[i * 3 + 1] = Math.random() * 10 + 1
      positions[i * 3 + 2] = (Math.random() - 0.5) * 14
    }
    const geometry = new THREE.BufferGeometry()
    geometry.setAttribute("position", new THREE.BufferAttribute(positions, 3))
    const material = new THREE.PointsMaterial({
      color: 0xcfe6ff,
      size: 0.05,
      transparent: true,
      opacity: 0,
      depthWrite: false
    })
    const points = new THREE.Points(geometry, material)
    points.visible = false
    points.userData.count = count
    return points
  }

  setWeather(weather) {
    this.weather = weather in SKY ? weather : "clear"
    const [ top, bottom ] = SKY[this.weather]
    this.scene.background = new THREE.Color(top)
    this.scene.fog = new THREE.Fog(bottom, 14, 34)
    this.ground.material.color.setHex(this.weather === "dry" ? 0x8d9a4f : 0x5f8a4a)
    this.sun.intensity = this.weather === "rain" ? 0.55 : this.weather === "dry" ? 1.55 : 1.35
    this.hemi.intensity = this.weather === "rain" ? 0.75 : 1.05
    this.rain.visible = this.weather === "rain"
    this.rain.material.opacity = this.weather === "rain" ? 0.75 : 0
  }

  syncPlots(plots) {
    const seen = new Set()
    plots.forEach((plot, index) => {
      const id = String(plot.id)
      seen.add(id)
      let bed = this.beds.get(id)
      if (!bed) {
        bed = this.createBed(plot, index)
        this.beds.set(id, bed)
        this.scene.add(bed.group)
      }
      this.placeBed(bed, index)
      this.updateBed(bed, plot)
    })

    this.beds.forEach((bed, id) => {
      if (seen.has(id)) return
      this.scene.remove(bed.group)
      this.beds.delete(id)
    })
  }

  createBed(plot, index) {
    const group = new THREE.Group()
    group.userData.plotId = String(plot.id)

    const soil = new THREE.Mesh(
      new THREE.BoxGeometry(BED, 0.28, BED),
      new THREE.MeshStandardMaterial({ color: 0x6b4228, roughness: 0.95 })
    )
    soil.position.y = 0.14
    soil.castShadow = true
    soil.receiveShadow = true
    soil.userData.pickable = true
    group.add(soil)

    const rim = new THREE.Mesh(
      new THREE.BoxGeometry(BED + 0.12, 0.12, BED + 0.12),
      new THREE.MeshStandardMaterial({ color: 0x8d5a34, roughness: 0.9 })
    )
    rim.position.y = 0.06
    rim.receiveShadow = true
    rim.userData.pickable = true
    group.add(rim)

    const highlight = new THREE.Mesh(
      new THREE.RingGeometry(0.95, 1.08, 32),
      new THREE.MeshBasicMaterial({ color: 0xf0c35a, transparent: true, opacity: 0, side: THREE.DoubleSide })
    )
    highlight.rotation.x = -Math.PI / 2
    highlight.position.y = 0.3
    group.add(highlight)

    const cropRoot = new THREE.Group()
    cropRoot.position.y = 0.28
    group.add(cropRoot)

    this.placeBed({ group }, index)
    return { group, soil, rim, highlight, cropRoot, crop: null, plot }
  }

  placeBed(bed, index) {
    const col = index % COLS
    const row = Math.floor(index / COLS)
    const x = (col - 1) * (BED + GAP) + 1.1
    const z = row * (BED + GAP) - 1.4
    bed.group.position.set(x, 0, z)
  }

  updateBed(bed, plot) {
    bed.plot = plot
    const progress = this.progressFor(plot)
    const stage = plot.state === "growing"
      ? (progress >= 0.85 ? "ripe" : progress >= 0.55 ? "leaf" : progress >= 0.25 ? "sprout" : "seed")
      : plot.state

    bed.soil.material.color.setHex(plot.state === "spoiled" ? 0x4a4038 : 0x6b4228)
    bed.highlight.material.opacity = this.selectedId === String(plot.id) ? 0.95 : plot.state === "ready" ? 0.45 : 0
    bed.highlight.material.color.setHex(plot.state === "ready" ? 0xf0c35a : 0xffffff)

    const signature = `${plot.state}:${plot.crop}:${stage}`
    if (bed.signature === signature && plot.state !== "growing") return
    if (bed.signature?.startsWith(`${plot.state}:${plot.crop}:`) && plot.state === "growing" && bed.crop) {
      this.scaleCrop(bed.crop, plot.crop, progress)
      bed.signature = signature
      return
    }

    while (bed.cropRoot.children.length) {
      const child = bed.cropRoot.children.pop()
      child.geometry?.dispose?.()
      if (child.material) {
        if (Array.isArray(child.material)) child.material.forEach((m) => m.dispose())
        else child.material.dispose()
      }
    }
    bed.crop = null
    bed.signature = signature

    if (plot.state === "empty" || !plot.crop) return
    bed.crop = this.buildCrop(plot.crop, plot.state === "spoiled" ? 1 : progress, plot.state === "spoiled")
    bed.cropRoot.add(bed.crop)
  }

  progressFor(plot) {
    if (plot.state === "ready" || plot.state === "spoiled") return 1
    if (plot.state !== "growing" || !plot.plantedAt || !plot.readyAt) return 0
    const span = Math.max(plot.readyAt - plot.plantedAt, 1)
    return Math.min(Math.max((Date.now() - plot.plantedAt) / span, 0), 1)
  }

  buildCrop(crop, progress, spoiled) {
    const color = CROP_COLORS[crop] || 0x6a9a3e
    const group = new THREE.Group()
    group.userData.crop = crop

    if (crop === "apple") {
      const trunk = new THREE.Mesh(
        new THREE.CylinderGeometry(0.06, 0.1, 0.9, 6),
        new THREE.MeshStandardMaterial({ color: spoiled ? 0x5a4a3a : 0x6b4428 })
      )
      trunk.position.y = 0.45
      trunk.castShadow = true
      group.add(trunk)
      const canopy = new THREE.Mesh(
        new THREE.SphereGeometry(0.42, 10, 10),
        new THREE.MeshStandardMaterial({ color: spoiled ? 0x6d7058 : 0x3f7d3a })
      )
      canopy.position.y = 0.95
      canopy.castShadow = true
      group.add(canopy)
      if (progress > 0.7 && !spoiled) {
        const fruit = new THREE.Mesh(
          new THREE.SphereGeometry(0.09, 8, 8),
          new THREE.MeshStandardMaterial({ color })
        )
        fruit.position.set(0.22, 0.78, 0.12)
        fruit.castShadow = true
        group.add(fruit)
      }
    } else if (crop === "wheat") {
      for (let i = 0; i < 7; i += 1) {
        const stalk = new THREE.Mesh(
          new THREE.CylinderGeometry(0.015, 0.02, 0.7, 4),
          new THREE.MeshStandardMaterial({ color: spoiled ? 0x7a6a4a : 0x7f9a3e })
        )
        stalk.position.set((i % 3) * 0.18 - 0.18, 0.35, Math.floor(i / 3) * 0.18 - 0.18)
        stalk.castShadow = true
        group.add(stalk)
        const head = new THREE.Mesh(
          new THREE.BoxGeometry(0.05, 0.18, 0.05),
          new THREE.MeshStandardMaterial({ color: spoiled ? 0x6d5a38 : color })
        )
        head.position.copy(stalk.position)
        head.position.y = 0.72
        group.add(head)
      }
    } else if (crop === "lettuce" || crop === "pumpkin") {
      const leaf = new THREE.Mesh(
        new THREE.SphereGeometry(crop === "pumpkin" ? 0.28 : 0.32, 10, 10),
        new THREE.MeshStandardMaterial({ color: spoiled ? 0x6d7058 : crop === "pumpkin" ? color : 0x4f8f3d })
      )
      leaf.position.y = crop === "pumpkin" ? 0.22 : 0.2
      leaf.scale.y = crop === "pumpkin" ? 0.75 : 0.55
      leaf.castShadow = true
      group.add(leaf)
    } else if (crop === "radish") {
      const top = new THREE.Mesh(
        new THREE.ConeGeometry(0.12, 0.28, 6),
        new THREE.MeshStandardMaterial({ color: spoiled ? 0x6d7058 : 0x3f8a3a })
      )
      top.position.y = 0.28
      top.castShadow = true
      group.add(top)
      const bulb = new THREE.Mesh(
        new THREE.SphereGeometry(0.12, 10, 10),
        new THREE.MeshStandardMaterial({ color: spoiled ? 0x5a4038 : color })
      )
      bulb.position.y = 0.1
      bulb.scale.y = 1.25
      bulb.castShadow = true
      group.add(bulb)
    } else {
      const stem = new THREE.Mesh(
        new THREE.CylinderGeometry(0.03, 0.04, 0.55, 6),
        new THREE.MeshStandardMaterial({ color: spoiled ? 0x5a4a3a : 0x3f7a38 })
      )
      stem.position.y = 0.28
      stem.castShadow = true
      group.add(stem)
      const leaf = new THREE.Mesh(
        new THREE.SphereGeometry(0.16, 8, 8),
        new THREE.MeshStandardMaterial({ color: spoiled ? 0x6d7058 : 0x4f8f3d })
      )
      leaf.position.set(0.12, 0.42, 0)
      leaf.scale.set(1.4, 0.35, 1)
      group.add(leaf)
      const fruit = new THREE.Mesh(
        new THREE.SphereGeometry(0.1, 8, 8),
        new THREE.MeshStandardMaterial({ color: spoiled ? 0x5a4038 : color })
      )
      fruit.position.set(-0.08, 0.48, 0.05)
      fruit.castShadow = true
      group.add(fruit)
    }

    this.scaleCrop(group, crop, progress)
    return group
  }

  scaleCrop(group, crop, progress) {
    const t = Math.max(0.12, Math.min(progress, 1))
    if (crop === "apple") group.scale.setScalar(0.35 + t * 0.65)
    else if (crop === "wheat") group.scale.set(1, 0.25 + t * 0.75, 1)
    else group.scale.setScalar(0.25 + t * 0.75)
  }

  select(plotId) {
    this.selectedId = plotId ? String(plotId) : null
    this.beds.forEach((bed) => {
      const selected = this.selectedId === String(bed.plot.id)
      bed.highlight.material.opacity = selected ? 0.95 : bed.plot.state === "ready" ? 0.45 : 0
    })
  }

  pick(clientX, clientY) {
    const rect = this.canvas.getBoundingClientRect()
    this.pointer.x = ((clientX - rect.left) / rect.width) * 2 - 1
    this.pointer.y = -((clientY - rect.top) / rect.height) * 2 + 1
    this.raycaster.setFromCamera(this.pointer, this.camera)
    const meshes = []
    this.beds.forEach((bed) => {
      bed.group.traverse((obj) => {
        if (obj.isMesh && obj.userData.pickable) meshes.push(obj)
      })
    })
    const hits = this.raycaster.intersectObjects(meshes, false)
    if (!hits.length) return null
    let node = hits[0].object
    while (node && !node.userData.plotId) node = node.parent
    return node?.userData.plotId || null
  }

  zoomBy(factor) {
    const offset = this.camera.position.clone().sub(this.controls.target)
    const next = Math.min(
      this.controls.maxDistance,
      Math.max(this.controls.minDistance, offset.length() * factor)
    )
    offset.setLength(next)
    this.camera.position.copy(this.controls.target).add(offset)
    this.controls.update()
  }

  zoomIn() {
    this.zoomBy(0.82)
  }

  zoomOut() {
    this.zoomBy(1.22)
  }

  resetView() {
    this.camera.position.set(DEFAULT_CAMERA.x, DEFAULT_CAMERA.y, DEFAULT_CAMERA.z)
    this.controls.target.set(DEFAULT_TARGET.x, DEFAULT_TARGET.y, DEFAULT_TARGET.z)
    this.controls.update()
  }

  resize() {
    const width = this.canvas.clientWidth || this.canvas.parentElement?.clientWidth || 640
    const height = this.canvas.clientHeight || 420
    this.renderer.setSize(width, height, false)
    this.camera.aspect = width / Math.max(height, 1)
    this.camera.updateProjectionMatrix()
  }

  start() {
    if (this.running) return
    this.running = true
    this.tick()
  }

  stop() {
    this.running = false
    cancelAnimationFrame(this.frame)
  }

  dispose() {
    this.stop()
    this.controls?.dispose()
    this.beds.clear()
    try { this.renderer.forceContextLoss() } catch (_) { /* ignore */ }
    this.renderer.dispose()
    if (this.renderer.domElement && this.renderer.domElement === this.canvas) {
      // Leave the canvas node for Turbo/Stimulus to replace; clear the GL binding.
      this.renderer.domElement = null
    }
  }

  tick = () => {
    if (!this.running) return
    this.frame = requestAnimationFrame(this.tick)
    const delta = this.clock.getDelta()
    const elapsed = this.clock.elapsedTime

    this.controls.update()

    if (this.weather === "rain" && this.rain.visible) {
      const positions = this.rain.geometry.attributes.position.array
      for (let i = 0; i < this.rain.userData.count; i += 1) {
        positions[i * 3 + 1] -= (8 + (i % 5)) * Math.max(delta, 0.008)
        if (positions[i * 3 + 1] < 0) positions[i * 3 + 1] = 10 + Math.random() * 2
      }
      this.rain.geometry.attributes.position.needsUpdate = true
    }

    this.beds.forEach((bed) => {
      if (bed.plot?.state === "growing") this.updateBed(bed, bed.plot)
      if (bed.crop && !this.reducedMotion) {
        bed.crop.rotation.y = Math.sin(elapsed * 1.4 + bed.group.position.x) * 0.04
      }
    })

    this.renderer.render(this.scene, this.camera)
  }
}
