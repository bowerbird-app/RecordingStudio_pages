# frozen_string_literal: true

RecordingStudioPages.configure do |config|
  config.page_parent_types = %w[Workspace Folder]
  config.homepage_path = "/"
  config.register_built_in_sections = true
end
