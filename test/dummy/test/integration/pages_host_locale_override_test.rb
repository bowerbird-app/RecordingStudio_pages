# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "yaml"

class PagesHostLocaleOverrideTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  HOST_SUBTITLE = "HOST pages index subtitle"
  # Override key: recording_studio.pages.index.subtitle

  setup do
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
  end

  test "host locale file overrides gem pages index subtitle on the real admin pages index" do
    with_host_locale_override(
      "en" => {
        "recording_studio" => {
          "pages" => {
            "index" => {
              "subtitle" => HOST_SUBTITLE
            }
          }
        }
      }
    ) do
      get recording_studio_pages.admin_pages_path

      assert_response :success
      assert_includes response.body, HOST_SUBTITLE
      refute_includes response.body, "Compose a public page from registered sections."
    end
  end

  test "default english index subtitle is unchanged outside the host override" do
    get recording_studio_pages.admin_pages_path

    assert_response :success
    assert_includes response.body, "Compose a public page from registered sections."
    refute_includes response.body, HOST_SUBTITLE
  end

  private

  # Test-only host locale: write a temp YAML file, put it on I18n.load_path after
  # the engine, reload, then restore path + translations so other tests keep the
  # default English UI.
  def with_host_locale_override(tree)
    path = Rails.root.join("tmp/zz_pages_host_override.en.yml")
    FileUtils.mkdir_p(path.dirname)
    File.write(path, YAML.dump(tree))
    original = I18n.load_path.dup

    begin
      I18n.load_path << path.to_s
      I18n.backend.load_translations
      yield
    ensure
      I18n.load_path.replace(original)
      FileUtils.rm_f(path)
      I18n.backend.load_translations
    end
  end
end
