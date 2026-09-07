===============================================================================

RecordingStudioPages has been installed successfully!

The engine has been mounted at /recording_studio_pages.

Next:

1. Add RecordingStudioPages::Page and RecordingStudioPages::Section to recordable_types.
2. Copy migrations with `bin/rails generate recording_studio_pages:migrations`.
3. Point `/` at `recording_studio_pages/homepages#show`.
4. Mount RecordingStudioPublishable::Engine at `/` for `/pages/:uuid/:slug`.
5. Register extra sections in the `:register_sections` hook. The engine resets registries on reload.

===============================================================================
