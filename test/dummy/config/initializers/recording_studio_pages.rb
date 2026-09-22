# frozen_string_literal: true

RecordingStudioPages.configure do |config|
  config.page_parent_types = %w[Workspace Folder]
  config.homepage_path = "/"
  config.register_built_in_sections = true

  config.hooks.on(:register_ctas) do
    RecordingStudioPages.register_cta(
      key: :social_logins,
      name: "Social logins",
      source: "dummy",
      component: "Dummy::Ctas::SocialLoginsComponent"
    )
    RecordingStudioPages.register_cta(
      key: :url_form,
      name: "URL field",
      source: "dummy",
      component: "Dummy::Ctas::UrlFormComponent",
      fields: {
        placeholder: { type: :string, label: "Placeholder" },
        button_text: { type: :string, label: "Button text" }
      }
    )
  end
end
