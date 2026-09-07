RecordingStudioPages install complete.

Next steps:

1. Review config/initializers/recording_studio_pages.rb.
2. Add `RecordingStudioPages::Page` and `RecordingStudioPages::Section` to `RecordingStudio.configuration.recordable_types`.
3. Install Orderable's position column, Publishable's table, and Attachable if Publishable 0.2.1 is in the host. Publishable includes Attachable even when you only want slug and status.
4. Install the engine migrations with `bin/rails generate recording_studio_pages:migrations`.
5. Apply the migrations with `bin/rails db:migrate`.
6. Mount Publishable at `/` and set `root to: "recording_studio_pages/homepages#show"`. Do not mount this engine at `/` if RS Admin already owns `/admin`.
7. Bundle and mount RecordingStudioDuplicatable. Copy on a section uses `duplicate_in_place!`.
8. Adjust auth, layout, and current actor integration to match your host app. Public pages must use a full-width layout that loads `flat_pack/variables` then `flat_pack/application` then Tailwind, with `data-theme="rounded"` on `html`. Do not reuse a sign-in layout (`max-w-md`).
9. Define `recording_studio_pages_page_nav` if gem screens should share host chrome. Install Trashable if remove should use `trash!`.
10. Register custom sections in the `:register_sections` hook. The engine resets registries on reload.
11. Point Tailwind `@source` at this gem's `app/views` and `app/components`, then run `bin/rails tailwindcss:build`.
12. Keep strict recordable declarations enabled and add `recording_studio_recordable(...)` to every configured recordable before running `RecordingStudio.validate_recordable_declarations!`.
