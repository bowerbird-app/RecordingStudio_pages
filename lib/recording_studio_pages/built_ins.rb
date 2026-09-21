# frozen_string_literal: true

module RecordingStudioPages
  module BuiltIns
    module_function

    def register!
      register_ctas!
      register_sections!
    end

    def register_ctas!
      register_button_cta!
    end

    def register_sections!
      register_top_nav!
      register_hero!
      register_rich_text!
      register_image_text!
      register_logo_cloud!
      register_feature_grid!
      register_call_to_action!
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

    def register_top_nav!
      RecordingStudioPages.register_section(
        key: :top_nav,
        name: "Menu",
        category: "marketing",
        source: "recording_studio_pages",
        component: "RecordingStudioPages::Sections::TopNavComponent",
        full_bleed: true,
        fields: {
          name: { type: :string, label: "Name" },
          image: { type: :attachment, kind: :image, label: "Mark" },
          links: {
            type: :list,
            label: "Links",
            item: {
              text: { type: :string, label: "Label" },
              url: { type: :url, label: "URL" }
            }
          },
          cta: { type: :cta, label: "Join" }
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
        full_bleed: true,
        fields: {
          eyebrow: :string,
          title: { type: :string, required: true },
          body: :rich_text,
          image: { type: :attachment, kind: :image, label: "Image" },
          cta: :cta
        },
        settings: {
          variant: :string,
          alignment: {
            type: :string,
            label: "Align",
            default: "center",
            group: :style,
            options: [
              %w[Center center],
              %w[Left left]
            ]
          },
          background: {
            type: :string,
            label: "Preset",
            default: "dark",
            group: :style,
            show_when: { variant: "fullscreen_image", image: true },
            options: [
              ["On a dark photo", "dark"],
              ["On a light photo", "light"]
            ]
          },
          eyebrow_color: {
            type: :color,
            label: "Eyebrow",
            group: :style
          },
          title_color: {
            type: :color,
            label: "Headline",
            group: :style
          },
          body_color: {
            type: :color,
            label: "Subtitle",
            group: :style
          }
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
          body: :rich_text,
          image: { type: :attachment, kind: :image, label: "Image" }
        },
        settings: {
          variant: :string,
          background: {
            type: :string,
            label: "Background",
            default: "default",
            options: [
              %w[Default default],
              %w[Muted muted],
              %w[Inverted inverted]
            ]
          }
        },
        variants: %w[full_width narrow]
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
