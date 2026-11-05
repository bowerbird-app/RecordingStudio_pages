# frozen_string_literal: true

# Dummy omits recording_studio_terms_and_conditions until that gem ships a
# recording_studio 6.x floor (latest tag v0.14.2 still requires ~> 4.2).
if defined?(RecordingStudioTermsAndConditions)
  RecordingStudioTermsAndConditions.configure do |config|
    # Shown in the signup continue notice: "By continuing, you agree to Page Builder's…"
    config.app_name = "Page Builder"
  end
end
