# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Pin FlatPack controllers
pin_all_from FlatPack::Engine.root.join("app/javascript/flat_pack/controllers"), under: "controllers/flat_pack", to: "flat_pack/controllers", preload: false
pin "flat_pack/heroicons", to: "flat_pack/heroicons.js", preload: false

pin_all_from RecordingStudioPages::Engine.root.join("app/javascript/recording_studio_pages/controllers"),
             under: "controllers/recording_studio_pages",
             to: "recording_studio_pages/controllers",
             preload: false

pin "@rails/activestorage", to: "activestorage.esm.js"
pin_all_from RecordingStudioAttachable::Engine.root.join("app/javascript/controllers/recording_studio_attachable"),
  under: "controllers/recording_studio_attachable",
  to: "controllers/recording_studio_attachable"
