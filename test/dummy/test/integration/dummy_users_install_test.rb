# frozen_string_literal: true

require "test_helper"

class DummyUsersInstallTest < ActionDispatch::IntegrationTest
  test "dummy credentials enable Google and Apple continue-with providers" do
    assert RecordingStudioUser.config.omniauth_configured?
    assert_equal %i[google_oauth2 apple], RecordingStudioUser.config.omniauth_provider_names
    assert User.devise_modules.include?(:omniauthable)
  end

  test "sign in and the Join CTA share Users continue-with buttons" do
    get new_user_session_path

    assert_response :success
    assert_includes response.body, "Continue with Google"
    assert_includes response.body, 'action="/users/auth/google_oauth2"'

    actor = create_actor!("join-cta@example.com")
    root = create_workspace_root!("Join CTA #{SecureRandom.hex(4)}")
    page_recording = create_page!(parent_recording: root, title: "Join", actor: actor)
    RecordingStudioPages::Services::ApplyTemplate.call(
      page_recording: page_recording,
      template_key: "join",
      actor: actor
    ).value!
    publishable = publish_page!(page_recording, slug: "join-cta", actor: actor)

    get "/pages/#{publishable.id}/join-cta"

    assert_response :success
    assert_includes response.body, "Continue with Google"
    assert_includes response.body, "Continue with Apple"
    assert_includes response.body, 'action="/users/auth/google_oauth2"'
    assert_includes response.body, 'action="/users/auth/apple"'
    refute_includes response.body, 'href="/users/sign_in"'
  end
end
