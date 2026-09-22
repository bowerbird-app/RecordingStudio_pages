===============================================================================

RecordingStudioPages has been installed successfully!

The engine has been mounted at /recording_studio_pages.

Next:

1. Add RecordingStudioPages::Page and RecordingStudioPages::Section to recordable_types.
2. Copy migrations with `bin/rails generate recording_studio_pages:migrations`.
3. Point `/` at `recording_studio_pages/homepages#show`.
4. Mount RecordingStudioPublishable::Engine at `/` for `/pages/:uuid/:slug`.
5. Bundle and mount RecordingStudioDuplicatable so Copy on a section uses `duplicate_in_place!`.
6. Register extra sections in the `:register_sections` hook and extra hero fillings in `:register_ctas`. The engine resets registries on reload.
7. Load Flatpack CSS (`flat_pack/application`) with the host theme on `html` (`FlatPack.configuration.default_theme`). Load Flatpack Stimulus so a Menu’s **More** control works on a phone. Do not reuse a sign-in layout. Put `recording_studio_pages_flash` in the layout that wraps page builder screens. Pin Publishable `0.3.0`. Public pages should render Publishable’s document title, head tags, and Preview badge. Import Turbo so the editor’s Draft/Published control can publish in place.
8. Gem screens use Recording Studio page nav (back and close). Install Trashable so page **Trash** calls `recording_studio_trashable_trash!`.

===============================================================================
