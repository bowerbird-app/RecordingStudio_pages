# frozen_string_literal: true

require "test_helper"
require "yaml"
require "tmpdir"
require "fileutils"

class LocalesTest < ActiveSupport::TestCase
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
    "fallbacks.more" => "More"
  }.freeze

  test "engine ships only english locale files" do
    files = Dir[File.join(engine_locales_dir, "*")].map { |path| File.basename(path) }

    assert_equal ["en.yml"], files.sort
  end

  test "rails i18n load path includes the gem english locale file" do
    locale_path = File.join(engine_locales_dir, "en.yml")

    assert_includes I18n.load_path.map { |path| File.expand_path(path) }, File.expand_path(locale_path)
  end

  test "english page keys resolve without missing translations" do
    I18n.with_locale(:en) do
      EXPECTED.each do |key, english|
        full_key = "recording_studio.pages.#{key}"
        translation = I18n.t(full_key, default: nil)

        assert_equal english, translation, "#{full_key} should resolve to #{english.inspect}"
        assert_equal english, I18n.t(full_key, raise: true)
      end
    end
  end

  test "interpolated keys expand values" do
    I18n.with_locale(:en) do
      assert_equal(
        "The saved content is still here. Register hero to edit it.",
        I18n.t("recording_studio.pages.sections.unregistered_description", section_type: "hero")
      )
      assert_equal "Link text", I18n.t("recording_studio.pages.fields.link_text", label: "Link")
      assert_equal "Add a feature", I18n.t("recording_studio.pages.sections.empty_children_title", name: "feature")
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

  test "engine registers locales initializer" do
    names = RecordingStudioPages::Engine.initializers.map(&:name)
    assert_includes names, "recording_studio_pages.locales"
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
end
