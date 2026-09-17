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
    house_menu = lambda do
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
      }
    end
    register_home = lambda do |key:, name:, title:, body:, image:, alignment:, tone:|
      RecordingStudioPages.register_template(
        key: key,
        name: name,
        source: "dummy",
        sections: [
          house_menu.call,
          {
            type: :hero,
            content: { title: title, body: body, image: image },
            settings: { variant: "fullscreen_image", alignment: alignment, tone: tone }
          }
        ]
      )
    end
    register_home.call(
      key: :home,
      name: "Home Dark",
      title: "The page is the front door",
      body: "Come in if you want a seat.",
      image: "/images/hero-tonight.jpg",
      alignment: "center",
      tone: "dark"
    )
    register_home.call(
      key: :home_left,
      name: "Home Left",
      title: "Come sit on this side",
      body: "The light is already on.",
      image: "/images/hero-home-left-pastel.png",
      alignment: "left",
      tone: "light"
    )
    register_home.call(
      key: :home_center,
      name: "Home Center",
      title: "Meet us in the middle",
      body: "The floor is already warm.",
      image: "/images/hero-home-center-pastel.png",
      alignment: "center",
      tone: "light"
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
