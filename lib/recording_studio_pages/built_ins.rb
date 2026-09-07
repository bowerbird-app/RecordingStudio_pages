# frozen_string_literal: true

module RecordingStudioPages
  module BuiltIns
    module_function

    def register!
      register_sections!
      register_templates!
    end

    def register_sections!
      register_hero!
      register_rich_text!
      register_image_text!
      register_logo_cloud!
      register_feature_grid!
      register_call_to_action!
    end

    def register_templates!
      register_marketing_home_template!
      register_full_bleed_hero_template!
    end

    def register_marketing_home_template!
      RecordingStudioPages.register_template(
        key: :marketing_home,
        name: "Marketing home",
        source: "recording_studio_pages",
        sections: [
          {
            type: :hero,
            content: {
              eyebrow: "Recording Studio",
              title: "Build pages from recordings",
              body: "Compose a public page from approved sections. No freeform HTML, no parallel CMS tables.",
              primary_action: { text: "Get started", url: "/users/sign_in" }
            },
            settings: { variant: "centered", alignment: "left" }
          },
          {
            type: :logo_cloud,
            content: {
              title: "Trusted by teams that already live in the tree",
              items: [
                { name: "Recording Studio" },
                { name: "Publishable" },
                { name: "Admin" }
              ]
            }
          },
          {
            type: :feature_grid,
            content: {
              title: "What this gem owns",
              items: [
                { title: "Pages", body: "A page is a recording with a title and an ordered list of sections." },
                { title: "Sections", body: "Every section uses the same generic recording. section_type picks the implementation." },
                { title: "Registry", body: "Other gems register new sections without a migration." }
              ]
            },
            settings: { variant: "three_column" }
          },
          {
            type: :call_to_action,
            content: {
              title: "Publish when it is ready",
              body: "Drafts stay private. RS Publishable owns live state and SEO.",
              primary_action: { text: "Open pages", url: "/admin" }
            }
          }
        ]
      )
    end

    def register_full_bleed_hero_template!
      RecordingStudioPages.register_template(
        key: :full_bleed_hero,
        name: "Full-bleed hero",
        source: "recording_studio_pages",
        sections: [
          {
            type: :hero,
            content: {
              eyebrow: "Doors at eight",
              title: "The floor is already warm",
              body: "One picture. One line. Come in if you want a seat.",
              primary_action: { text: "Take a seat", url: "/users/sign_in" }
            },
            settings: { variant: "fullscreen_image" }
          }
        ]
      )
    end

    def register_hero!
      RecordingStudioPages.register_section(
        key: :hero,
        name: "Hero",
        category: "marketing",
        source: "recording_studio_pages",
        component: "RecordingStudioPages::Sections::HeroComponent",
        fields: {
          eyebrow: :string,
          title: { type: :string, required: true },
          body: :rich_text,
          image_url: :url,
          primary_action: :link
        },
        settings: {
          variant: :string,
          alignment: :string,
          background: :string
        },
        variants: %w[centered split_image fullscreen_image]
      )
    end

    def register_rich_text!
      RecordingStudioPages.register_section(
        key: :rich_text,
        name: "Rich text",
        category: "content",
        source: "recording_studio_pages",
        component: "RecordingStudioPages::Sections::RichTextComponent",
        fields: {
          title: { type: :string, required: true },
          body: :rich_text
        },
        settings: {
          variant: :string
        },
        variants: %w[article narrow]
      )
    end

    def register_image_text!
      RecordingStudioPages.register_section(
        key: :image_text,
        name: "Image and text",
        category: "content",
        source: "recording_studio_pages",
        component: "RecordingStudioPages::Sections::ImageTextComponent",
        fields: {
          title: { type: :string, required: true },
          body: :rich_text,
          image_url: :url,
          primary_action: :link
        },
        settings: {
          variant: :string
        },
        variants: %w[image_left image_right]
      )
    end

    def register_logo_cloud!
      RecordingStudioPages.register_section(
        key: :logo_cloud,
        name: "Logo cloud",
        category: "marketing",
        source: "recording_studio_pages",
        component: "RecordingStudioPages::Sections::LogoCloudComponent",
        fields: {
          title: :string,
          items: {
            type: :list,
            item: { name: :string, url: :url, image_url: :url }
          }
        },
        settings: {
          variant: :string
        },
        variants: %w[simple compact]
      )
    end

    def register_feature_grid!
      RecordingStudioPages.register_section(
        key: :feature_grid,
        name: "Feature grid",
        category: "marketing",
        source: "recording_studio_pages",
        component: "RecordingStudioPages::Sections::FeatureGridComponent",
        fields: {
          title: { type: :string, required: true },
          body: :text,
          items: {
            type: :list,
            item: { title: :string, body: :text }
          }
        },
        settings: {
          variant: :string
        },
        variants: %w[three_column icon_grid alternating_rows]
      )
    end

    def register_call_to_action!
      RecordingStudioPages.register_section(
        key: :call_to_action,
        name: "Call to action",
        category: "marketing",
        source: "recording_studio_pages",
        component: "RecordingStudioPages::Sections::CallToActionComponent",
        fields: {
          title: { type: :string, required: true },
          body: :text,
          primary_action: :link
        },
        settings: {
          variant: :string,
          background: :string
        },
        variants: %w[centered banner]
      )
    end
  end
end
