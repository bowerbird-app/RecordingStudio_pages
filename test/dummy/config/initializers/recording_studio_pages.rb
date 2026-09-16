# frozen_string_literal: true

RecordingStudioPages.configure do |config|
  config.page_parent_types = %w[Workspace Folder]
  config.homepage_path = "/site"
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

  config.hooks.on(:register_sections) do
    RecordingStudioPages.register_template(
      key: :home,
      name: "Home",
      source: "dummy",
      sections: [
        {
          type: :top_nav,
          content: {
            name: "House",
            links: [
              { text: "About", url: "/" },
              { text: "Tonight", url: "/" }
            ],
            cta: { type: "button", text: "Join", url: "/users/sign_in" }
          }
        },
        {
          type: :hero,
          content: {
            title: "The page is the front door",
            body: "Come in if you want a seat.",
            image: "/images/hero-tonight.jpg"
          },
          settings: { variant: "fullscreen_image" }
        }
      ]
    )
    RecordingStudioPages.register_template(
      key: :join,
      name: "Join",
      source: "dummy",
      sections: [
        {
          type: :hero,
          content: {
            eyebrow: "Members",
            title: "Come as you are",
            body: "Use the door you already have.",
            cta: { type: "social_logins" }
          },
          settings: { variant: "centered" }
        }
      ]
    )
    RecordingStudioPages.register_template(
      key: :start_from_url,
      name: "Start from a URL",
      source: "dummy",
      sections: [
        {
          type: :hero,
          content: {
            eyebrow: "Quick start",
            title: "Got a link?",
            body: "Paste it. We'll take it from there.",
            cta: {
              type: "url_form",
              placeholder: "https://",
              button_text: "Open it"
            }
          },
          settings: { variant: "centered" }
        }
      ]
    )
    RecordingStudioPages.register_template(
      key: :walk_in,
      name: "Walk in",
      source: "dummy",
      sections: [
        {
          type: :hero,
          content: {
            eyebrow: "Members",
            title: "The lights are already on",
            body: "Use the door you already have.",
            image_url: "/images/hero-tonight.jpg",
            cta: { type: "social_logins" }
          },
          settings: { variant: "fullscreen_image" }
        }
      ]
    )
  end
end
