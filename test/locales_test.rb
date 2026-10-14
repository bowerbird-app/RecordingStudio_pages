# frozen_string_literal: true

require "test_helper"
require "yaml"
require "tmpdir"
require "fileutils"

class LocalesTest < ActiveSupport::TestCase
  # I18n interpolation tokens use %{name}; RuboCop prefers %<name>s for Kernel#format.
  # rubocop:disable Style/FormatStringToken
  EXPECTED = {
    "layout.page" => "Page",
    "index.title" => "Pages",
    "index.subtitle" => "Compose a public page from registered sections.",
    "index.new_page" => "Page",
    "index.empty_title" => "Nothing here yet",
    "index.empty_description" => "Add a page to get going.",
    "index.column_page" => "Page",
    "index.column_home" => "Home",
    "index.home_badge" => "Home",
    "index.open" => "Open",
    "new.title" => "New page",
    "new.subtitle" => "Give it a name. You can add sections next.",
    "new.name" => "Name",
    "new.homepage" => "Use as the public home page",
    "new.create" => "Create page",
    "edit.title" => "Settings",
    "edit.name" => "Name",
    "edit.homepage" => "Use as the public home page",
    "edit.save" => "Save",
    "editor.unknown_sections_title" => "Some sections are waiting on a missing type",
    "editor.unknown_sections_description" =>
      "Their content is still saved. Register the section type to edit them again.",
    "editor.empty_sections_title" => "Add your first section",
    "editor.empty_sections_description" => "Open Section and pick a type.",
    "editor.preview_title" => "Preview",
    "editor.preview_description" => "Turn a section on and it shows up here.",
    "add_section.label" => "Section",
    "settings.label" => "Settings",
    "settings.trash" => "Trash",
    "settings.trash_confirm" => "Trash this page?",
    "section_actions.actions" => "Actions",
    "section_actions.edit" => "Edit",
    "section_actions.copy" => "Copy",
    "section_actions.turn_off" => "Turn off",
    "section_actions.turn_on" => "Turn on",
    "section_actions.remove" => "Remove",
    "sections.edit_title" => "Edit section",
    "sections.unknown" => "Unknown section",
    "sections.update" => "Update",
    "sections.cancel" => "Cancel",
    "sections.unregistered_title" => "This section type is not registered",
    "sections.unregistered_description" =>
      "The saved content is still here. Register %{section_type} to edit it.",
    "sections.nothing_preview_title" => "Nothing to preview",
    "sections.nothing_preview_description" => "Register this type and it shows up here.",
    "sections.call_to_action" => "Call to action",
    "sections.layout" => "Layout",
    "sections.style" => "Style",
    "sections.cta_label" => "Call to action",
    "sections.cta_none" => "None",
    "sections.cta_draws_itself" => "This one draws itself. Nothing to fill in.",
    "sections.add_child" => "Add",
    "sections.empty_children_title" => "Add a %{name}",
    "sections.empty_children_piece" => "piece",
    "sections.empty_children_description" => "They show up on the page.",
    "fields.link_text" => "%{label} text",
    "fields.link_url" => "%{label} URL",
    "fields.remove_item" => "Remove this item",
    "fields.add_item" => "Add %{item}",
    "fields.recording_ids" => "%{label} (one id per line)",
    "attachment.empty" => "No picture yet.",
    "attachment.choose" => "Choose image",
    "attachment.remove" => "Remove",
    "attachment.modal_title" => "Choose an image",
    "attachment.search_aria" => "Search images",
    "attachment.empty_state" => "No pictures here yet. Upload one.",
    "fallbacks.next_step" => "Next step",
    "fallbacks.features" => "Features",
    "fallbacks.logos" => "Logos",
    "fallbacks.logo" => "Logo",
    "fallbacks.notes" => "Notes",
    "fallbacks.image_and_text" => "Image and text",
    "fallbacks.untitled" => "Untitled",
    "fallbacks.mark" => "Mark",
    "fallbacks.more" => "More",
    "flashes.page_created" => "Page created.",
    "flashes.page_saved" => "Page saved.",
    "flashes.in_the_trash" => "In the trash.",
    "flashes.updated" => "Updated.",
    "flashes.section_removed" => "Section removed.",
    "flashes.section_copied" => "Section copied.",
    "flashes.section_added" => "Section added.",
    "flashes.named_section_added" => "%{name} added.",
    "flashes.choose_place" => "Choose a place in the list.",
    "flashes.public_home_is" => "Public home is %{path}.",
    "errors.choose_workspace" => "Choose a workspace for this page.",
    "errors.pages_belong_in_workspace" => "Pages belong in a workspace or folder.",
    "errors.section_belongs_under_parent" => "%{name} belongs under its parent section.",
    "errors.section_sits_on_page" => "A section sits on a page or another section.",
    "errors.section_does_not_belong" => "%{name} does not belong on this section.",
    "errors.no_access_to_copy" => "You don't have access to copy this section.",
    "admin.section.title" => "Pages",
    "admin.section.subtitle" => "Compose public pages from registered sections",
    "admin.resource.trash_confirm" => "Trash this page?",
    "built_ins.sections.hero.name" => "Hero",
    "built_ins.sections.hero.fields.image" => "Image",
    "built_ins.ctas.button.name" => "Button",
    "built_ins.ctas.button.fields.text" => "Button text"
  }.freeze
  # rubocop:enable Style/FormatStringToken

  test "engine ships only english locale files" do
    files = Dir[File.join(engine_locales_dir, "*")].map { |path| File.basename(path) }

    assert_equal ["en.yml"], files.sort
  end

  test "engine exposes config/locales for rails to load" do
    locale_path = File.expand_path(File.join(engine_locales_dir, "en.yml"))
    engine_locale_paths = RecordingStudioPages::Engine.paths["config/locales"].existent.map do |path|
      File.expand_path(path)
    end

    assert_includes engine_locale_paths, locale_path
  end

  test "english page keys resolve without missing translations" do
    with_gem_english_locales do
      I18n.with_locale(:en) do
        EXPECTED.each do |key, english|
          full_key = "recording_studio.pages.#{key}"
          translation = I18n.t(full_key, default: nil)

          assert_equal english, translation, "#{full_key} should resolve to #{english.inspect}"
          assert_equal english, I18n.t(full_key, raise: true)
        end
      end
    end
  end

  test "interpolated keys expand values" do
    with_gem_english_locales do
      I18n.with_locale(:en) do
        assert_equal(
          "The saved content is still here. Register hero to edit it.",
          I18n.t("recording_studio.pages.sections.unregistered_description", section_type: "hero")
        )
        assert_equal "Link text", I18n.t("recording_studio.pages.fields.link_text", label: "Link")
        assert_equal "Add a feature", I18n.t("recording_studio.pages.sections.empty_children_title", name: "feature")
      end
    end
  end

  test "en.yml nests keys under recording_studio.pages" do
    tree = locale_tree(File.join(engine_locales_dir, "en.yml"), "en")
           .fetch("recording_studio")
           .fetch("pages")

    assert tree.key?("index")
    assert tree.key?("fallbacks")
    refute tree.key?("recording_studio_pages")
  end

  test "gem does not ship a top-level recording_studio_pages locale namespace" do
    tree = locale_tree(File.join(engine_locales_dir, "en.yml"), "en")

    refute tree.key?("recording_studio_pages")
  end

  test "engine does not register an explicit locales load path initializer" do
    names = RecordingStudioPages::Engine.initializers.map(&:name)

    refute_includes names, "recording_studio_pages.locales"
    engine_source = File.read(File.expand_path("../lib/recording_studio_pages/engine.rb", __dir__))
    refute_includes engine_source, "config.i18n.load_path"
    refute_includes engine_source, "I18n.load_path"
  end

  test "lib ruby files never mention i18n load path" do
    Dir[File.expand_path("../lib/**/*.rb", __dir__)].each do |path|
      source = File.read(path)
      refute_includes source, "i18n.load_path", path
      refute_includes source, "I18n.load_path", path
    end
  end

  test "copy helpers resolve english through RecordingStudio.t without missing translations" do
    with_gem_english_locales do
      I18n.with_locale(:en) do
        assert_equal "Page created.", RecordingStudioPages::Copy.t("flashes.page_created")
        assert_equal "Hero", RecordingStudioPages::Copy.section_name("hero", default: "Hero")
        assert_equal "Button text", RecordingStudioPages::Copy.field_label("ctas", "button", "text", default: "Button text")
      end
    end
  end

  test "engine registers shipped english before recording_studio loads the merged table" do
    names = RecordingStudioPages::Engine.initializers.map(&:name)
    assert_includes names, "recording_studio_pages.register_shipped_english"

    engine_source = File.read(File.expand_path("../lib/recording_studio_pages/engine.rb", __dir__))
    assert_includes engine_source, "register_shipped_english"
    assert_includes engine_source, 'before: "recording_studio.load_shipped_english"'
  end

  test "restores i18n load path after temporary mutation" do
    original = I18n.load_path.dup
    extra = File.join(Dir.tmpdir, "recording_studio_pages_locale_probe.yml")
    File.write(extra, "en:\n  probe: true\n")

    begin
      I18n.load_path << extra
      assert_includes I18n.load_path, extra
    ensure
      I18n.load_path.replace(original)
      FileUtils.rm_f(extra)
    end

    assert_equal original, I18n.load_path
  end

  private

  def engine_locales_dir
    File.expand_path("../config/locales", __dir__)
  end

  def locale_tree(path, locale)
    YAML.safe_load_file(path, aliases: true).fetch(locale)
  end

  # Unit suite does not boot the dummy app. Seed gem English via store_translations
  # and restore a deep backend snapshot afterward. Host-override coverage lives in
  # test/dummy/test/integration/pages_host_locale_override_test.rb.
  def with_gem_english_locales
    snapshot = i18n_backend_translations_snapshot
    tree = locale_tree(File.join(engine_locales_dir, "en.yml"), "en")
    I18n.backend.store_translations(:en, tree)
    yield
  ensure
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
      value.transform_values { |child| deep_plain_copy(child) }
    when Array
      value.map { |child| deep_plain_copy(child) }
    else
      value
    end
  end
end
