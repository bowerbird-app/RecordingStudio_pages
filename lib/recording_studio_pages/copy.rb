# frozen_string_literal: true

require "i18n"

module RecordingStudioPages
  # Rails I18n lookups for Pages user-facing copy. Every call passes
  # `default:` English so a host locale without a fallback never shows
  # "translation missing". Keys live under `recording_studio.pages.*`.
  #
  # Lib/services keep main's English literals. Controllers and views call
  # `user_message` to map those known English strings to locale keys at render.
  module Copy
    PREFIX = "recording_studio.pages"

    STATIC_ERROR_KEYS = {
      "Choose a workspace for this page." => "errors.choose_workspace",
      "Pages belong in a workspace or folder." => "errors.pages_belong_in_workspace",
      "A section sits on a page or another section." => "errors.section_sits_on_page",
      "You don't have access to copy this section." => "errors.no_access_to_copy",
      "Enable Recording Studio Duplicatable on the section type before copying sections" =>
        "errors.enable_duplicatable",
      "Enable Recording Studio Orderable on the page type before reordering sections" =>
        "errors.enable_orderable",
      "Install Recording Studio Trashable before removing this." => "errors.install_trashable"
    }.freeze

    FIELD_ERROR_PATTERNS = [
      [/\A(.+) is required\z/, "errors.field_required", :key],
      [/\A(.+) must be a URL\z/, "errors.field_must_be_url", :key],
      [/\A(.+) must be true or false\z/, "errors.field_must_be_boolean", :key],
      [/\A(.+) must be an integer\z/, "errors.field_must_be_integer", :key],
      [/\A(.+) must be a list\z/, "errors.field_must_be_list", :key],
      [/\A(.+) must be a list of recording ids\z/, "errors.field_must_be_recording_ids", :key],
      [/\A(.+) must be a colour\z/, "errors.field_must_be_colour", :key],
      [/\A(.+) must be an image or a URL\z/, "errors.field_must_be_image_or_url", :key],
      [/\A(.+) is not a registered field\z/, "errors.field_not_registered", :key],
      [/\A(.+)\.url must be a http, https, or relative path\z/, "errors.link_url_must_be_safe", :key],
      [/\Avariant must be one of: (.+)\z/, "errors.variant_must_be_one_of", :variants],
      [/\A(.+) belongs under its parent section\.\z/, "errors.section_belongs_under_parent", :name],
      [/\A(.+) does not belong on this section\.\z/, "errors.section_does_not_belong", :name]
    ].freeze

    module_function

    def t(key, **)
      I18n.t("#{PREFIX}.#{key}", **)
    end

    def section_name(key, default:)
      t("built_ins.sections.#{key}.name", default: default)
    end

    def cta_name(key, default:)
      t("built_ins.ctas.#{key}.name", default: default)
    end

    def field_label(owner_kind, owner_key, field_key, default:)
      return default if default.blank?

      t("built_ins.#{owner_kind}.#{owner_key}.fields.#{field_key}", default: default)
    end

    def option_label(owner_kind, owner_key, field_key, value, default:)
      t(
        "built_ins.#{owner_kind}.#{owner_key}.options.#{field_key}.#{value}",
        default: default
      )
    end

    def translate_options(owner_kind, owner_key, field_key, options)
      Array(options).map do |entry|
        label, value = Array(entry)
        value = label if value.nil?
        [
          option_label(owner_kind, owner_key, field_key, value, default: label.to_s),
          value
        ]
      end
    end

    # Map a lib/service English message to a locale string at render time.
    # Unknown messages pass through unchanged.
    def user_message(message)
      english = message.to_s
      return english if english.blank?
      return translate_joined_message(english) if english.include?(", ")
      return t(STATIC_ERROR_KEYS[english], default: english) if STATIC_ERROR_KEYS.key?(english)

      translate_pattern_message(english) || english
    end

    def translate_joined_message(english)
      english.split(", ").map { |part| user_message(part.strip) }.join(", ")
    end

    def translate_pattern_message(english)
      FIELD_ERROR_PATTERNS.each do |pattern, key, capture|
        match = pattern.match(english)
        return t(key, capture => match[1], default: english) if match
      end
      nil
    end
  end
end
