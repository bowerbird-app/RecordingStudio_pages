# frozen_string_literal: true

require "test_helper"

class PagesHostLocaleOverrideTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  HOST_SUBTITLE = "HOST pages index subtitle"
  HOST_CHOOSE_PLACE = "HOST Choose a place in the list."
  SUBTITLE_KEY = "recording_studio.pages.index.subtitle"
  CHOOSE_PLACE_KEY = "recording_studio.pages.flashes.choose_place"
  BOOT_HOST_LOCALE = Rails.root.join("config/locales/recording_studio_pages_host.en.yml")
  FRESH_HOST_LOCALE = Rails.root.join("test/locales/pages_host_override.en.yml")

  setup do
    @load_path_before = I18n.load_path.dup
    @backend_before = I18n.backend
    @actor = create_actor!("host-locale-pages@example.com")
    @root = create_workspace_root!("Host Locale Workspace #{SecureRandom.hex(4)}")
    @admin_root = create_admin_root!
    grant_admin!(@admin_root, @actor)
    grant_admin!(@root, @actor)
    Current.actor = @actor
    sign_in @actor
  end

  teardown do
    Current.actor = nil
    I18n.backend = @backend_before if @backend_before
    assert_equal @load_path_before, I18n.load_path,
                 "test must not leave I18n.load_path modified"
  end

  # Real-boot-order guard: host file under config/locales must win without any
  # test-time load_path mutation. Render assertion uses the bad-reorder flash.
  test "host locale override for recording_studio.pages wins on boot order" do
    assert File.exist?(BOOT_HOST_LOCALE)
    assert_includes File.read(BOOT_HOST_LOCALE), HOST_CHOOSE_PLACE
    assert_equal HOST_CHOOSE_PLACE, I18n.t(CHOOSE_PLACE_KEY)
    assert_equal @load_path_before, I18n.load_path,
                 "boot-order test must not mutate I18n.load_path"

    page_recording = create_page!(parent_recording: @root, title: "Boot order page", actor: @actor)
    section = add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Hero" },
      actor: @actor
    )

    patch recording_studio_pages.reorder_admin_page_sections_path(page_recording),
          params: { moving_recording_id: section.id, target_position: 0 },
          as: :json

    assert_response :unprocessable_content
    assert_equal HOST_CHOOSE_PLACE, response.parsed_body["error"]
  end

  # Test-only fixture applied via backend.load_translations(file) on top of the
  # already-initialized backend — never mutates I18n.load_path (Marshal).
  test "host locale file overrides gem pages index subtitle on the real admin pages index" do
    assert File.exist?(FRESH_HOST_LOCALE), "expected test-only host override fixture at #{FRESH_HOST_LOCALE}"
    assert_includes File.read(FRESH_HOST_LOCALE), HOST_SUBTITLE

    snapshot = i18n_backend_translations_snapshot
    I18n.t(SUBTITLE_KEY)
    I18n.backend.load_translations(FRESH_HOST_LOCALE.to_s)

    assert_equal @load_path_before, I18n.load_path
    assert_equal HOST_SUBTITLE, I18n.t(SUBTITLE_KEY)
    assert_equal HOST_CHOOSE_PLACE, I18n.t(CHOOSE_PLACE_KEY)

    get recording_studio_pages.admin_pages_path

    assert_response :success
    assert_includes response.body, HOST_SUBTITLE
    refute_includes response.body, "Compose a public page from registered sections."
  ensure
    restore_i18n_backend_translations(snapshot) if snapshot
  end

  test "default english index subtitle is unchanged outside the host override" do
    get recording_studio_pages.admin_pages_path

    assert_response :success
    assert_includes response.body, "Compose a public page from registered sections."
    refute_includes response.body, HOST_SUBTITLE
  end

  private

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
