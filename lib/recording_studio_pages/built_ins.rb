# frozen_string_literal: true

module RecordingStudioPages
  module BuiltIns
    module_function

    def register!
      register_ctas!
      register_sections!
      register_templates!
    end

    def register_ctas!
      register_button_cta!
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
              eyebrow: "Open tonight",
              title: "The page is the front door",
              body: "Stack a few pieces. Move them around. Put it live when it feels like a site.",
              cta: { type: "button", text: "Come in", url: "/users/sign_in" }
            },
            settings: { variant: "centered", alignment: "left" }
          },
          {
            type: :logo_cloud,
            content: {
              title: "Names on the door",
              items: [
                { name: "House lights" },
                { name: "Late show" },
                { name: "Stage door" }
              ]
            }
          },
          {
            type: :feature_grid,
            content: {
              title: "What you get",
              items: [
                { title: "Pages", body: "A page is a stack you can reorder." },
                { title: "Pieces", body: "Each piece has a job. Change the layout without starting over." },
                { title: "Reuse", body: "Add a type once, then drop it on any page." }
              ]
            },
            settings: { variant: "three_column" }
          },
          {
            type: :call_to_action,
            content: {
              title: "Ready when you are",
              body: "Keep it private until it looks right. Then put it on the street.",
              primary_action: { text: "Have a look", url: "/users/sign_in" }
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
              cta: { type: "button", text: "Take a seat", url: "/users/sign_in" }
            },
            settings: { variant: "fullscreen_image" }
          }
        ]
      )
    end

    def register_button_cta!
      RecordingStudioPages.register_cta(
        key: :button,
        name: "Button",
        source: "recording_studio_pages",
        component: "RecordingStudioPages::Ctas::ButtonComponent",
        fields: {
          text: { type: :string, label: "Button text" },
          url: { type: :url, label: "Button URL" }
        }
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
          image: { type: :attachment, kind: :image, label: "Image" },
          cta: :cta
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
          image: { type: :attachment, kind: :image, label: "Image" },
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
            item: {
              name: :string,
              url: :url,
              image: { type: :attachment, kind: :image, label: "Image" }
            }
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
