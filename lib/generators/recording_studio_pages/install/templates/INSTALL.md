RecordingStudioPages install complete.

Next steps:

1. Review config/initializers/recording_studio_pages.rb.
2. Add `RecordingStudioPages::Page` and `RecordingStudioPages::Section` to `RecordingStudio.configuration.recordable_types`.
3. Install Orderable's position column and Publishable's table if those gems are in the host.
4. Install the engine migrations with `bin/rails generate recording_studio_pages:migrations`.
5. Apply the migrations with `bin/rails db:migrate`.
6. Mount Publishable at `/` and set `root to: "recording_studio_pages/homepages#show"`. Do not mount this engine at `/` if RS Admin already owns `/admin`.
7. Register custom sections in the `:register_sections` hook. The engine resets registries on reload.
8. Run `bin/rails tailwindcss:build` if you use Tailwind CSS.
9. Keep strict recordable declarations enabled and run `RecordingStudio.validate_recordable_declarations!`.
