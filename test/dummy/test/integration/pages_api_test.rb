# frozen_string_literal: true

require "test_helper"

class PagesApiTest < ActionDispatch::IntegrationTest
  BASE = "/recording_studio_api/api/v1"

  setup do
    @previous_actor = Current.actor
    @owner = user("owner")
    @editor = user("editor")
    @viewer = user("viewer")
    Current.actor = @owner
    @workspace = owned_root(Workspace.create!(name: "API Pages #{SecureRandom.hex(4)}"))
    @stranger = user("stranger")
    @other = owned_root(Workspace.create!(name: "Other workspace #{SecureRandom.hex(4)}"), actor: @stranger)
    @editor_access = grant!(@workspace, @editor, :edit)
    @viewer_access = grant!(@workspace, @viewer, :view)
    @editor_token, = token_for(@editor_access)
    @viewer_token, = token_for(@viewer_access)
  end

  teardown { Current.actor = @previous_actor }

  test "catalog lists registered sections for view access" do
    body = call(:get, "/pages_catalog", @editor_token)
    assert_response :success, response.body
    assert body.fetch("sections").any? { |section| section.fetch("key") == "hero" }
    assert body.key?("ctas")

    call(:get, "/pages_catalog", @viewer_token)
    assert_response :success, response.body
  end

  test "create_page revise_page add_section and revise_section go through pages services" do
    created = call(:post, "/pages", @editor_token, parent_id: @workspace.id, title: "Tonight", homepage: false)
    assert_response :created, response.body
    assert_equal "Tonight", created.fetch("title")
    assert_equal false, created.fetch("homepage")
    page_id = created.fetch("id")
    assert_equal "Tonight", RecordingStudio::Recording.find(page_id).recordable.title

    revised = call(:patch, "/pages/#{page_id}", @editor_token, title: "Tonight live")
    assert_response :success, response.body
    assert_equal "Tonight live", revised.fetch("title")

    added = call(:post, "/page_sections/#{page_id}/add", @editor_token, section_type: "hero", content: { title: "Hello" })
    assert_response :success, response.body
    assert_equal "hero", added.fetch("section_type")
    assert_equal "Hello", added.fetch("content").fetch("title")
    section_id = added.fetch("id")

    updated = call(:patch, "/sections/#{section_id}", @editor_token, content: { title: "Hello again" })
    assert_response :success, response.body
    assert_equal "Hello again", updated.fetch("content").fetch("title")
  end

  test "duplicate_section and toggle_section wrap the pages services" do
    page = create_page!(parent_recording: @workspace, title: "Copy me", actor: @owner)
    section = add_section!(page_recording: page, section_type: "hero", content: { title: "One" }, actor: @owner)

    copy = call(:post, "/page_sections/#{section.id}/duplicate", @editor_token)
    assert_response :success, response.body
    refute_equal section.id, copy.fetch("id")
    assert_equal "hero", copy.fetch("section_type")

    toggled = call(:post, "/page_sections/#{section.id}/toggle", @editor_token, enabled: false)
    assert_response :success, response.body
    assert_equal false, toggled.fetch("enabled")
    assert_equal false, section.reload.recordable.enabled?
  end

  test "unauthenticated calls are 401" do
    get "#{BASE}/pages_catalog", as: :json
    assert_response :unauthorized

    post "#{BASE}/pages", params: { parent_id: @workspace.id, title: "Nope" }, as: :json
    assert_response :unauthorized

    patch "#{BASE}/pages/#{SecureRandom.uuid}", params: { title: "Nope" }, as: :json
    assert_response :unauthorized

    post "#{BASE}/page_sections/#{SecureRandom.uuid}/add", params: { section_type: "hero" }, as: :json
    assert_response :unauthorized

    patch "#{BASE}/sections/#{SecureRandom.uuid}", params: { content: { title: "Nope" } }, as: :json
    assert_response :unauthorized

    post "#{BASE}/page_sections/#{SecureRandom.uuid}/duplicate", as: :json
    assert_response :unauthorized

    post "#{BASE}/page_sections/#{SecureRandom.uuid}/toggle", params: { enabled: false }, as: :json
    assert_response :unauthorized
  end

  test "view can read catalog and is forbidden from writes" do
    page = create_page!(parent_recording: @workspace, title: "Look", actor: @owner)
    section = add_section!(page_recording: page, section_type: "hero", content: { title: "Stay" }, actor: @owner)

    call(:post, "/pages", @viewer_token, parent_id: @workspace.id, title: "No")
    assert_response :forbidden, response.body

    call(:patch, "/pages/#{page.id}", @viewer_token, title: "No")
    assert_response :forbidden, response.body

    call(:post, "/page_sections/#{page.id}/add", @viewer_token, section_type: "hero", content: { title: "No" })
    assert_response :forbidden, response.body

    call(:patch, "/sections/#{section.id}", @viewer_token, content: { title: "No" })
    assert_response :forbidden, response.body

    call(:post, "/page_sections/#{section.id}/duplicate", @viewer_token)
    assert_response :forbidden, response.body

    call(:post, "/page_sections/#{section.id}/toggle", @viewer_token, enabled: false)
    assert_response :forbidden, response.body
  end

  test "a page or section in another workspace is not found" do
    stranger_page = create_page!(parent_recording: @other, title: "Elsewhere", actor: @stranger)
    stranger_section = add_section!(
      page_recording: stranger_page,
      section_type: "hero",
      content: { title: "Away" },
      actor: @stranger
    )

    call(:patch, "/pages/#{stranger_page.id}", @editor_token, title: "Nope")
    assert_response :not_found, response.body

    call(:post, "/pages", @editor_token, parent_id: @other.id, title: "Nope")
    assert_response :not_found, response.body

    call(:post, "/page_sections/#{stranger_page.id}/add", @editor_token, section_type: "hero", content: { title: "Nope" })
    assert_response :not_found, response.body

    call(:patch, "/sections/#{stranger_section.id}", @editor_token, content: { title: "Nope" })
    assert_response :not_found, response.body

    call(:post, "/page_sections/#{stranger_section.id}/duplicate", @editor_token)
    assert_response :not_found, response.body

    call(:post, "/page_sections/#{stranger_section.id}/toggle", @editor_token, enabled: false)
    assert_response :not_found, response.body
  end

  test "unknown section type and bad section input are 422" do
    page = create_page!(parent_recording: @workspace, title: "Form", actor: @owner)
    section = add_section!(page_recording: page, section_type: "hero", content: { title: "Hero" }, actor: @owner)

    call(:post, "/page_sections/#{page.id}/add", @editor_token, section_type: "not_a_section")
    assert_response :unprocessable_entity, response.body

    call(:post, "/page_sections/#{page.id}/add", @editor_token, section_type: "hero", content: { title: "" })
    assert_response :unprocessable_entity, response.body

    call(:patch, "/sections/#{section.id}", @editor_token, content: { title: "" })
    assert_response :unprocessable_entity, response.body

    call(:post, "/pages", @editor_token, parent_id: page.id, title: "Nested")
    assert_response :unprocessable_entity, response.body
  end

  test "pages api registration matches builder roles and skips auto mixins" do
    page = RecordingStudioApi.recordable_registration_for("RecordingStudioPages::Page")
    section = RecordingStudioApi.recordable_registration_for("RecordingStudioPages::Section")
    assert_equal %i[create update], page.operations
    assert_equal %i[update], section.operations
    assert_equal false, page.auto_capability_actions
    assert_equal false, section.auto_capability_actions
    assert_equal RecordingStudioPages::Api::PageResource::Create,
                 RecordingStudioApi.resource_handler("RecordingStudioPages::Page", :create)
    assert_equal RecordingStudioPages::Api::SectionResource::Update,
                 RecordingStudioApi.resource_handler("RecordingStudioPages::Section", :update)

    catalog = RecordingStudioApi.registered_endpoint("pages.catalog")
    add = RecordingStudioApi.registered_endpoint("sections.add")
    assert_equal "Page - Catalog", catalog.openapi[:title]
    assert_equal "Section - Add", add.openapi[:title]
    assert_equal false, add.input_contract.as_json[:reject_unknown]
  end

  private

  def user(name)
    User.create!(
      email: "#{name}-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
  end

  def owned_root(recordable, actor: @owner)
    root = RecordingStudio.root_recording_for(recordable)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: root, actor: actor)
    raise result.error if result.failure?

    root
  end

  def grant!(recording, actor, role)
    result = RecordingStudioAccessible.grant_access(recording: recording, actor: actor, role: role, manager_actor: @owner)
    raise result.error if result.failure?

    result.value
  end

  def token_for(access_recording)
    RecordingStudioAccessible::AccessCreationContext.allow do
      provision = RecordingStudioApi::Services::ProvisionApiClient.call(
        access_point_recording: access_recording.parent_recording || access_recording.root_recording,
        manager_actor: @owner,
        role: access_recording.recordable.role.to_sym,
        name: "Client #{SecureRandom.hex(3)}"
      )
      raise provision.error unless provision.success?

      issued = RecordingStudioApi::Services::IssueOauthAccessToken.call(
        grant_type: "client_credentials",
        client_id: provision.value.fetch(:credential).oauth_client_id,
        client_secret: provision.value.fetch(:token)
      )
      raise issued.error unless issued.success?

      [issued.value.fetch(:access_token), provision.value.fetch(:api_client)]
    end
  end

  def call(method, path, token, params = {})
    send(method, "#{BASE}#{path}", params: params, headers: {
      "Authorization" => "Bearer #{token}",
      "Accept" => "application/json"
    }, as: :json)
    response.media_type.to_s.include?("json") ? JSON.parse(response.body) : {}
  rescue JSON::ParserError
    {}
  end
end
