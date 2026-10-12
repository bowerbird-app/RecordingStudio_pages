# frozen_string_literal: true

require "i18n"

module RecordingStudioPages
  # Rails I18n lookups for Pages user-facing copy. Every call passes
  # `default:` English so a host locale without a fallback never shows
  # "translation missing". Keys live under `recording_studio.pages.*`.
  module Copy
    PREFIX = "recording_studio.pages"

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

    def variant_must_be_one_of(variants)
      list = Array(variants).join(", ")
      t("errors.variant_must_be_one_of", variants: list, default: "variant must be one of: #{list}")
    end
  end
end
