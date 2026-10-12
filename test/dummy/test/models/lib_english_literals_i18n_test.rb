# frozen_string_literal: true

require "test_helper"

# Public lib return values and raised service messages stay main's English even
# under a non-English locale. Controllers translate via Copy.user_message at render.
class LibEnglishLiteralsI18nTest < ActiveSupport::TestCase
  test "field schema validation messages stay english under fr" do
    schema = RecordingStudioPages::FieldSchema.new(
      title: { type: :string, required: true },
      url: { type: :url }
    )

    with_locale(:fr) do
      assert_equal ["title is required"], schema.validate({})
      assert_includes schema.validate("url" => "not-a-url"), "url must be a URL"
      assert_includes schema.validate("url" => "not-a-url"), "title is required"
      assert_equal ["extra is not a registered field"], schema.validate("extra" => "x", "title" => "ok")
    end
  end

  test "section definition variant error stays english under fr" do
    definition = RecordingStudioPages::SectionDefinition.new(
      key: :literal_hero,
      name: "Literal hero",
      component: "RecordingStudioPages::Sections::HeroComponent",
      settings: { variant: :string },
      variants: %w[centered full_width]
    )

    with_locale(:fr) do
      errors = definition.validate_payload(content: {}, settings: { "variant" => "nope" })
      assert_equal ["variant must be one of: centered, full_width"], errors
    end
  end

  test "service errors stay english under fr" do
    with_locale(:fr) do
      create = RecordingStudioPages::Services::CreatePage.call(
        parent_recording: nil,
        title: "Nope",
        actor: nil
      )
      assert create.failure?
      assert_equal "Choose a workspace for this page.", create.error

      recording = Object.new
      def recording.has_attribute?(_name) = false

      trash = RecordingStudioPages::Services::TrashRecording.call(recording: recording, actor: nil)
      assert trash.failure?
      assert_equal "Install Recording Studio Trashable before removing this.", trash.error
    end
  end

  test "copy user_message maps known english at render and leaves unknowns" do
    available_before = I18n.available_locales.dup
    snapshot = i18n_backend_translations_snapshot
    I18n.available_locales = (available_before + [:fr]).uniq
    I18n.backend.store_translations(
      :fr,
      "recording_studio" => {
        "pages" => {
          "errors" => {
            "choose_workspace" => "Choisissez un espace.",
            "field_required" => "%{key} est requis",
            "variant_must_be_one_of" => "variant doit etre parmi: %{variants}",
            "link_url_must_be_safe" => "%{key}.url doit etre http, https, ou chemin relatif",
            "field_must_be_url" => "%{key} doit etre une URL"
          }
        }
      }
    )

    I18n.with_locale(:fr) do
      assert_equal "Choisissez un espace.",
                   RecordingStudioPages::Copy.user_message("Choose a workspace for this page.")
      assert_equal "title est requis",
                   RecordingStudioPages::Copy.user_message("title is required")
      assert_equal "variant doit etre parmi: centered, full_width",
                   RecordingStudioPages::Copy.user_message("variant must be one of: centered, full_width")
      assert_equal "cta.url doit etre http, https, ou chemin relatif",
                   RecordingStudioPages::Copy.user_message(
                     "cta.url must be a http, https, or relative path"
                   )
      assert_equal "title est requis, url doit etre une URL",
                   RecordingStudioPages::Copy.user_message("title is required, url must be a URL")
      assert_equal "totally unknown boom",
                   RecordingStudioPages::Copy.user_message("totally unknown boom")
    end
  ensure
    I18n.available_locales = available_before
    restore_i18n_backend_translations(snapshot) if snapshot
  end

  test "copy user_message preserves unmapped english byte for byte" do
    assert_equal "Two  spaces,  after comma",
                 RecordingStudioPages::Copy.user_message("Two  spaces,  after comma")
    assert_equal "Trailing comma, ",
                 RecordingStudioPages::Copy.user_message("Trailing comma, ")
    assert_equal " , ",
                 RecordingStudioPages::Copy.user_message(" , ")
  end

  private

  def with_locale(locale)
    available_before = I18n.available_locales.dup
    I18n.available_locales = (available_before + [locale]).uniq
    I18n.with_locale(locale) { yield }
  ensure
    I18n.available_locales = available_before
  end

  def i18n_backend_translations_snapshot
    backend = I18n.backend
    backend.send(:init_translations) unless backend.initialized?
    translations =
      if backend.respond_to?(:translations)
        backend.translations
      else
        backend.instance_variable_get(:@translations)
      end
    return unless translations

    deep_plain_copy(translations)
  end

  def restore_i18n_backend_translations(snapshot)
    backend = I18n.backend
    backend.instance_variable_set(:@translations, snapshot)
    backend.instance_variable_set(:@initialized, true) if backend.instance_variable_defined?(:@initialized)
  end

  def deep_plain_copy(value)
    case value
    when Hash
      value.transform_values { |child| deep_plain_copy(child) }
    when Array
      value.map { |child| deep_plain_copy(child) }
    else
      value
    end
  end
end
