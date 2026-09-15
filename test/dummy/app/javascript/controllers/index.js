import { application } from "controllers/application"
import { eagerLoadControllersFrom, lazyLoadControllersFrom } from "@hotwired/stimulus-loading"

// Lazy load controllers from the host app and FlatPack engine on first use.
lazyLoadControllersFrom("controllers", application)
lazyLoadControllersFrom("controllers/flat_pack", application)
eagerLoadControllersFrom("controllers/recording_studio_attachable", application)
