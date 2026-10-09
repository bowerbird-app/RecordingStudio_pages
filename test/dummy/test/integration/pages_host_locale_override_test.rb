# frozen_string_literal: true

require "test_helper"

class PagesHostLocaleOverrideTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

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
    get recording_studio_pages.admin_pages_path

    assert_response :success
    assert_includes response.body, "HOST pages index subtitle"
    refute_includes response.body, "Compose a public page from registered sections."
  end
end
