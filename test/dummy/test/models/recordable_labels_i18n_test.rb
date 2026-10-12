# frozen_string_literal: true

require "test_helper"

class RecordableLabelsI18nTest < ActiveSupport::TestCase
  test "page and section label constants stay english public api" do
    assert_equal "Page", RecordingStudioPages::Page::LABEL
    assert_equal "Pages", RecordingStudioPages::Page::PLURAL_LABEL
    assert_equal "Section", RecordingStudioPages::Section::LABEL
    assert_equal "Sections", RecordingStudioPages::Section::PLURAL_LABEL
  end

  test "recordable_type_label resolves english at call time" do
    with_pages_translations do
      I18n.with_locale(:en) do
        assert_equal "Page", RecordingStudioPages::Page.recordable_type_label
        assert_equal "Section", RecordingStudioPages::Section.recordable_type_label
      end
    end
  end

  test "recordable_type_label follows non-english locale with constant default" do
    available_before = I18n.available_locales.dup
    snapshot = i18n_backend_translations_snapshot
    I18n.available_locales = (available_before + [:fr]).uniq
    I18n.backend.store_translations(
      :fr,
      "recording_studio" => {
        "pages" => {
          "recordables" => {
            "page" => { "label" => "Page FR" },
            "section" => { "label" => "Section FR" }
          }
        }
      }
    )

    I18n.with_locale(:fr) do
      assert_equal "Page FR", I18n.t("recording_studio.pages.recordables.page.label")
      assert_equal "Page", RecordingStudioPages::Page::LABEL
      assert_equal "Page FR", RecordingStudioPages::Page.recordable_type_label
      assert_equal "Section", RecordingStudioPages::Section::LABEL
      assert_equal "Section FR", RecordingStudioPages::Section.recordable_type_label
    end
  ensure
    I18n.available_locales = available_before
    restore_i18n_backend_translations(snapshot) if snapshot
  end

  private

  def with_pages_translations(extra = {})
    snapshot = i18n_backend_translations_snapshot
    available_before = I18n.available_locales.dup
    en = YAML.safe_load_file(
      File.expand_path("../../../../config/locales/en.yml", __dir__),
      aliases: true
    ).fetch("en")
    I18n.backend.store_translations(:en, en)
    extra.each { |locale, tree| I18n.backend.store_translations(locale, tree.deep_stringify_keys) }
    I18n.available_locales = (available_before + extra.keys).uniq
    yield
  ensure
    I18n.available_locales = available_before if available_before
    restore_i18n_backend_translations(snapshot) if snapshot
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
      value.each_with_object({}) { |(key, child), copy| copy[key] = deep_plain_copy(child) }
    when Array
      value.map { |child| deep_plain_copy(child) }
    else
      value
    end
  end
end
