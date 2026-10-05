# frozen_string_literal: true

require "test_helper"
require "cgi"

class TermsSignupTest < ActionDispatch::IntegrationTest
  setup do
    @actor = create_actor!("terms-staff-#{SecureRandom.hex(4)}@example.com")
    Current.actor = @actor
    @workspace = Workspace.create!(name: "Terms Workspace #{SecureRandom.hex(4)}")
    @root = RecordingStudio.root_recording_for(@workspace)
    grant_admin!(@root, @actor)
    @terms = publish_document!(
      kind: "terms_and_condition",
      title: "House rules",
      body: "Be kind on the way in.",
      slug: "house-rules-#{SecureRandom.hex(3)}"
    )
    @privacy = publish_document!(
      kind: "privacy_policy",
      title: "Privacy Policy",
      body: "We keep the version you agreed to.",
      slug: "privacy-#{SecureRandom.hex(3)}"
    )
  end

  teardown do
    Current.actor = nil
  end

  test "create-password shows the continue notice and accepts both documents" do
    email = "signup-#{SecureRandom.hex(4)}@example.com"
    # Signup accepts against Gate.root_for_signup (first root with live Terms when
    # there is no current root). db:prepare seeds Studio Workspace with live docs,
    # so that root can win over @workspace depending on recording UUID order.
    signup_root = RecordingStudioTermsAndConditions::Gate.first_root_with_live_terms
    assert_predicate signup_root, :present?

    post "/users/sign_up", params: { user: { email: email } }
    assert_redirected_to "/users/sign_up/password"
    follow_redirect!

    assert_response :success
    assert_includes CGI.unescapeHTML(response.body), "By continuing, you agree"
    assert_includes response.body, "Terms &amp; Conditions"
    assert_match(/privacy policy/, response.body)
    assert_select "input[type=checkbox][name=agreed]", count: 0

    assert_difference -> { RecordingStudioTermsAndConditions::Acceptance.count }, 2 do
      post "/users/sign_up/password", params: { user: { email: email, password: "Password" } }
    end

    user = User.find_by!(email: email)
    assert RecordingStudioTermsAndConditions.accepted?(user, signup_root, kind: "terms_and_condition")
    assert RecordingStudioTermsAndConditions.accepted?(user, signup_root, kind: "privacy_policy")
    receipt = RecordingStudioTermsAndConditions::Acceptance.where(actor: user).order(:created_at).last
    assert_equal({ "source" => "continue_notice" }, receipt.provenance)
  end

  test "published terms and privacy pages are public" do
    get @terms.recordable.published_url
    assert_response :success
    assert_includes response.body, "House rules"
    assert_includes response.body, "Be kind on the way in."

    get @privacy.recordable.published_url
    assert_response :success
    assert_includes response.body, "Privacy Policy"
    assert_includes response.body, "We keep the version you agreed to."
  end

  private

  def publish_document!(kind:, title:, body:, slug:)
    recording = @root.record(RecordingStudioTermsAndConditions::Terms, actor: @actor) do |terms|
      terms.title = title
      terms.body = body
      terms.kind = kind
    end
    RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: recording,
      attributes: { slug: slug, status: "published" },
      actor: @actor
    ).value!
    recording.reload
  end
end
