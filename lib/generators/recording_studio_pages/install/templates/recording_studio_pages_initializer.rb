# frozen_string_literal: true

RecordingStudioPages.configure do |config|
  config.page_parent_types = %w[Workspace Folder]
  config.homepage_path = "/"
  config.register_built_in_sections = true
  # Leave layout unset (nil) to use Recording Studio's default layout.
  # Set a layout name, false, or ->(controller:) { ... } to override.
end
