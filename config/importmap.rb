# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "three", to: "three.module.min.js"
pin "three/addons/controls/OrbitControls", to: "OrbitControls.js"
pin "field/scene", to: "field/scene.js"
pin_all_from "app/javascript/controllers", under: "controllers"
