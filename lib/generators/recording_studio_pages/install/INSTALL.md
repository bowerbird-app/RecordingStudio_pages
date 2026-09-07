===============================================================================

RecordingStudioPages has been installed successfully!

The engine has been mounted at /recording_studio_pages.

Next:

1. Add RecordingStudioPages::Page and RecordingStudioPages::Section to recordable_types.
2. Copy migrations with `bin/rails generate recording_studio_pages:migrations`.
3. Point `/` at `recording_studio_pages/homepages#show`.
4. Mount RecordingStudioPublishable::Engine at `/` for `/pages/:uuid/:slug`.
5. Bundle and mount RecordingStudioDuplicatable so Copy on a section uses `duplicate_in_place!`.
6. Register extra sections in the `:register_sections` hook. The engine resets registries on reload.
7. Load Flatpack CSS (`flat_pack/application`) with `data-theme` on `html` for public pages. Do not reuse a sign-in layout.

===============================================================================
