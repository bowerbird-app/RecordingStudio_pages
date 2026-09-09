# frozen_string_literal: true

class AdminRoot < ApplicationRecord
  include RecordingStudio::Recordable
  include RecordingStudioAdmin::AllowsAdminSections if defined?(RecordingStudioAdmin::AllowsAdminSections)

  recording_studio_recordable label: "Admin", root: true, shared: false
  RecordingStudio.enable_capability(:accessible, on: self) if defined?(RecordingStudioAccessible)

  if defined?(RecordingStudioAdmin)
    recording_studio_admin_sections do
      section :pages
      section :users
    end
  end
end
