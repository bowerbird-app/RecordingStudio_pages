# frozen_string_literal: true

require "test_helper"

class StartsControllerTest < ActionDispatch::IntegrationTest
  test "a pasted URL shows up on the start page" do
    get start_path, params: { url: "https://example.com/show" }

    assert_response :success
    assert_includes response.body, "Got it"
    assert_includes response.body, "https://example.com/show"
    assert_includes response.body, 'data-theme="rounded"'
  end

  test "an empty start page asks for a link" do
    get start_path

    assert_response :success
    assert_includes response.body, "Nothing in the box yet"
  end
end
