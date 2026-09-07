# frozen_string_literal: true

require "test_helper"

class FieldSchemaTest < Minitest::Test
  def test_read_coerces_registered_shapes
    schema = RecordingStudioPages::FieldSchema.new(
      title: :string,
      featured: :boolean,
      count: :integer,
      action: :link,
      items: { type: :list, item: { name: :string } }
    )

    result = schema.read(
      title: "Hello",
      featured: "true",
      count: "3",
      action: { text: "Go", url: "/next" },
      items: [{ name: "One" }],
      extra: "drop me"
    )

    assert_equal "Hello", result["title"]
    assert_equal true, result["featured"]
    assert_equal 3, result["count"]
    assert_equal({ "text" => "Go", "url" => "/next" }, result["action"])
    assert_equal([{ "name" => "One" }], result["items"])
    refute result.key?("extra")
  end

  def test_validate_rejects_unregistered_fields_and_unsafe_urls
    schema = RecordingStudioPages::FieldSchema.new(title: :string, image_url: :url)

    errors = schema.validate(title: "Hi", image_url: "javascript:alert(1)", extra: "nope")

    assert_includes errors, "extra is not a registered field"
    assert(errors.any? { |error| error.include?("image_url") })
  end

  def test_relative_and_http_urls_are_allowed
    schema = RecordingStudioPages::FieldSchema.new(image_url: :url)

    assert_empty schema.validate(image_url: "/hero.png")
    assert_empty schema.validate(image_url: "https://example.com/hero.png")
  end
end
