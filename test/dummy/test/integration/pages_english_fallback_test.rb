# frozen_string_literal: true

require "test_helper"

# Behavioral renders: a locale without translations shows loaded / shipped
# English for Pages admin chrome via RecordingStudio.t. Uses :de so boot-loaded
# host English overrides and other locales do not interfere with the
# missing-locale case.
class PagesEnglishFallbackTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  INDEX_TITLE_KEY = "recording_studio.pages.index.title"
  INDEX_SUBTITLE_KEY = "recording_studio.pages.index.subtitle"
  CHOOSE_PLACE_KEY = "recording_studio.pages.flashes.choose_place"
  BOOT_HOST_LOCALE = Rails.root.join("config/locales/recording_studio_pages_host.en.yml")
  HOST_CHOOSE_PLACE = "HOST Choose a place in the list."

  setup do
    @actor = create_actor!("pages-english-fallback@example.com")
    @root = create_workspace_root!("English Fallback Workspace #{SecureRandom.hex(4)}")
    @admin_root = create_admin_root!
    grant_admin!(@admin_root, @actor)
    grant_admin!(@root, @actor)
    Current.actor = @actor
    sign_in @actor
    @previous_locales = I18n.available_locales
    I18n.available_locales = (@previous_locales + %i[en de fr]).uniq
    @load_path_before = I18n.load_path.dup
  end

  teardown do
    Current.actor = nil
    I18n.locale = I18n.default_locale
    I18n.available_locales = @previous_locales if @previous_locales
    assert_equal @load_path_before, I18n.load_path,
                 "test must not leave I18n.load_path modified"
  end

  test "missing locale without translations renders gem english on admin pages index" do
    I18n.with_locale(:de) do
      refute locale_has_own_translation?(:de, INDEX_TITLE_KEY),
             ":de must not ship its own index.title"

      get recording_studio_pages.admin_pages_path

      assert_response :success
      assert_includes @response.body, "Pages"
      assert_includes @response.body, "Compose a public page from registered sections."
      refute_match(/translation missing: [^"']*recording_studio\.pages/i, @response.body)
    end
  end

  test "english render matches gem english strings from main" do
    I18n.with_locale(:en) do
      get recording_studio_pages.admin_pages_path

      assert_response :success
      assert_includes @response.body, "Pages"
      assert_includes @response.body, "Compose a public page from registered sections."
      assert_includes @response.body, RecordingStudio.t("recording_studio.pages.index.new_page")
      refute_match(/translation missing: [^"']*recording_studio\.pages/i, @response.body)
    end
  end

  test "pages en.yml is registered for shipped english at boot without calling the initializer" do
    expected = File.expand_path(RecordingStudioPages::Engine.root.join("config/locales/en.yml"))
    paths = RecordingStudio::Translation.send(:registered_shipped_english_paths)

    assert_includes paths, expected,
                    "engine boot must register pages en.yml (do not call the initializer in this test)"
    assert_equal "Pages", RecordingStudio::Translation.shipped_english.fetch(INDEX_TITLE_KEY)
  end

  test "deleted english key on admin pages index shows shipped title without translation missing" do
    delete_loaded_translation!(:en, INDEX_TITLE_KEY)
    delete_loaded_translation!(:fr, INDEX_TITLE_KEY)

    refute I18n.exists?(INDEX_TITLE_KEY, :en)
    refute I18n.exists?(INDEX_TITLE_KEY, :fr)

    previous_raise = ActionView::Helpers::TranslationHelper.raise_on_missing_translations

    [false, true].each do |raise_on_missing|
      ActionView::Helpers::TranslationHelper.raise_on_missing_translations = raise_on_missing

      %i[en fr].each do |locale|
        I18n.with_locale(locale) do
          get recording_studio_pages.admin_pages_path

          assert_response :success
          assert_includes @response.body, "Pages"
          refute_match(/translation missing: [^"']*recording_studio\.pages/i, @response.body)
        end
      end
    end
  ensure
    ActionView::Helpers::TranslationHelper.raise_on_missing_translations = previous_raise
    I18n.reload!
  end

  test "boot-loaded host english override wins on real reorder flash page" do
    assert File.exist?(BOOT_HOST_LOCALE),
           "expected boot-loaded host override at #{BOOT_HOST_LOCALE}"
    assert_includes File.read(BOOT_HOST_LOCALE), HOST_CHOOSE_PLACE
    assert_equal @load_path_before, I18n.load_path

    # Force I18n to initialize before asserting host override (order-independent).
    I18n.t(CHOOSE_PLACE_KEY)
    assert_equal HOST_CHOOSE_PLACE, I18n.t(CHOOSE_PLACE_KEY)
    refute_equal "Choose a place in the list.", I18n.t(CHOOSE_PLACE_KEY)

    page_recording = create_page!(parent_recording: @root, title: "Fallback reorder", actor: @actor)
    section = add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Hero" },
      actor: @actor
    )

    I18n.with_locale(:de) do
      patch recording_studio_pages.reorder_admin_page_sections_path(page_recording),
            params: { moving_recording_id: section.id, target_position: 0 },
            as: :json

      assert_response :unprocessable_content
      assert_equal HOST_CHOOSE_PLACE, response.parsed_body["error"]
    end
  end

  test "shipped english table becomes a new object after rails reloader reload" do
    before = RecordingStudio::Translation.shipped_english
    refute_empty before
    assert_equal "Pages", before.fetch(INDEX_TITLE_KEY)

    previous_cache_classes = Rails.application.config.cache_classes
    Rails.application.config.cache_classes = false
    RecordingStudioMetrics.registry.reset! if defined?(RecordingStudioMetrics)

    Rails.application.reloader.reload!

    after = RecordingStudio::Translation.shipped_english
    refute_same before, after
    assert_equal "Pages", after.fetch(INDEX_TITLE_KEY)
  ensure
    Rails.application.config.cache_classes = previous_cache_classes unless previous_cache_classes.nil?
  end

  test "global I18n config keeps fallbacks load_path available_locales and exception handler" do
    snapshot = i18n_config_snapshot
    gem_en = File.expand_path(RecordingStudioPages::Engine.root.join("config/locales/en.yml"))
    boot_en = BOOT_HOST_LOCALE.to_s

    assert_includes snapshot.fetch(:load_path), File.expand_path(gem_en)
    assert_includes snapshot.fetch(:load_path), File.expand_path(boot_en)
    assert_operator snapshot.fetch(:load_path).index(File.expand_path(gem_en)),
                    :<,
                    snapshot.fetch(:load_path).index(File.expand_path(boot_en))
    assert snapshot.fetch(:exception_handler), "expected an I18n exception handler"
    assert_includes snapshot.fetch(:available_locales), :en

    RecordingStudio.t(INDEX_TITLE_KEY)
    assert_equal snapshot, i18n_config_snapshot
  end

  private

  def i18n_config_snapshot
    {
      load_path: I18n.load_path.map { |path| File.expand_path(path) },
      available_locales: Array(I18n.available_locales).map(&:to_sym).sort,
      exception_handler: I18n.exception_handler,
      enforce_available_locales: I18n.enforce_available_locales,
      fallbacks_class: (I18n.fallbacks.class.name if I18n.respond_to?(:fallbacks))
    }
  end

  def locale_has_own_translation?(locale, full_key)
    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    node = I18n.backend.send(:translations)[locale.to_sym]
    return false unless node.is_a?(Hash)

    full_key.split(".").map(&:to_sym).each do |part|
      return false unless node.is_a?(Hash) && node.key?(part)

      node = node[part]
    end
    true
  end

  def delete_loaded_translation!(locale, full_key)
    I18n.exists?(full_key, locale)
    parts = full_key.split(".").map(&:to_sym)
    leaf = parts.pop
    translations = I18n.backend.send(:translations)
    locale_key = locale.to_sym
    translations[locale_key] = translations[locale_key].dup if translations[locale_key].frozen?

    node = translations[locale_key]
    parts.each do |part|
      break unless node.is_a?(Hash) && node[part].is_a?(Hash)

      node[part] = node[part].dup if node[part].frozen?
      node = node[part]
    end
    node.delete(leaf) if node.is_a?(Hash)
  end
end
