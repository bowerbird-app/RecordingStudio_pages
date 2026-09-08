# frozen_string_literal: true

require "test_helper"

class DummyUsersInstallTest < ActionDispatch::IntegrationTest
  test "dummy credentials enable Google and Apple continue-with providers" do
    assert RecordingStudioUser.config.omniauth_configured?
    assert_equal %i[google_oauth2 apple], RecordingStudioUser.config.omniauth_provider_names
    assert User.devise_modules.include?(:omniauthable)
  end

  test "sign in and hero social CTAs post to the same Users OmniAuth paths" do
    get new_user_session_path

    assert_response :success
    assert_includes response.body, "Continue with Google"
    assert_includes response.body, 'action="/users/auth/google_oauth2"'

    actor = create_actor!("join-cta@example.com")
    Current.actor = actor
    root = create_workspace_root!("Join CTA #{SecureRandom.hex(4)}")
    grant_admin!(root, actor)
    page_recording = create_page!(parent_recording: root, title: "Walk in", actor: actor)
    RecordingStudioPages::Services::ApplyTemplate.call(
      page_recording: page_recording,
      template_key: "walk_in",
      actor: actor
    ).value!
    publishable = publish_page!(page_recording, slug: "walk-in-cta", actor: actor)

    get "/pages/#{publishable.id}/walk-in-cta"

    assert_response :success
    assert_includes response.body, "Continue with Google"
    assert_includes response.body, "Continue with Apple"
    assert_includes response.body, "max-w-sm"
    assert_includes response.body, 'action="/users/auth/google_oauth2"'
    assert_includes response.body, 'action="/users/auth/apple"'
    refute_includes response.body, 'href="/users/sign_in"'
    refute_includes response.body, ">Or<"
  end
end
