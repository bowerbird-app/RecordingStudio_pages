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

  def test_required_fields_and_recording_ids
    schema = RecordingStudioPages::FieldSchema.new(
      title: { type: :string, required: true },
      projects: :recording_ids
    )

    assert_includes schema.validate({}), "title is required"
    assert_equal %w[a b], schema.read(projects: "a\nb")["projects"]
    assert_equal true, schema.catalog[:title][:required]
  end

  def test_list_read_drops_blank_and_destroyed_items
    schema = RecordingStudioPages::FieldSchema.new(
      items: { type: :list, item: { name: :string, url: :url } }
    )

    result = schema.read(
      items: [
        { name: "Keep", url: "https://example.com" },
        { name: "", url: "" },
        { name: "Gone", url: "https://example.com/gone", "_destroy" => "1" },
        { name: "Also gone", "_destroy" => "true" }
      ]
    )

    assert_equal [{ "name" => "Keep", "url" => "https://example.com" }], result["items"]
  end

  def test_list_validate_skips_blank_and_destroyed_items
    schema = RecordingStudioPages::FieldSchema.new(
      items: { type: :list, item: { name: :string, url: :url } }
    )

    errors = schema.validate(
      items: [
        { name: "Keep", url: "javascript:alert(1)" },
        { name: "", url: "" },
        { name: "Gone", url: "javascript:alert(1)", "_destroy" => "1" }
      ]
    )

    assert(errors.any? { |error| error.include?("items[0]") })
    refute(errors.any? { |error| error.include?("items[1]") })
    refute(errors.any? { |error| error.include?("items[2]") })
  end

  def test_cta_coerces_legacy_link_shape_and_validates_registered_fields
    RecordingStudioPages.reset!
    RecordingStudioPages.register_cta(
      key: :button,
      name: "Button",
      component: "RecordingStudioPages::Ctas::ButtonComponent",
      fields: { text: :string, url: :url }
    )
    schema = RecordingStudioPages::FieldSchema.new(cta: :cta)

    result = schema.read(cta: { text: "Go", url: "/next" })

    assert_equal({ "type" => "button", "text" => "Go", "url" => "/next" }, result["cta"])
    assert_empty schema.validate(cta: { type: "button", text: "Go", url: "/next" })
    assert(schema.validate(cta: { type: "button", url: "javascript:alert(1)" }).any? { |error| error.include?("cta") })
    assert_empty schema.validate(cta: { type: "missing_widget", extra: "keep" })
  ensure
    RecordingStudioPages.reset!
    RecordingStudioPages::BuiltIns.register!
  end

  def test_cta_catalog_type
    schema = RecordingStudioPages::FieldSchema.new(
      cta: :cta,
      title: { type: :string, label: "Headline" }
    )

    assert_equal "cta", schema.catalog[:cta][:type]
    assert_equal "Headline", schema.catalog[:title][:label]
  end

  def test_attachment_coerces_ids_and_catalogs_kind
    schema = RecordingStudioPages::FieldSchema.new(
      image: { type: :attachment, kind: :image, label: "Image", required: true }
    )

    assert_equal "abc-123", schema.read(image: "abc-123")["image"]
    assert_nil schema.read(image: "")["image"]
    assert_equal "attachment", schema.catalog[:image][:type]
    assert_equal "image", schema.catalog[:image][:kind]
    assert_equal "Image", schema.catalog[:image][:label]
    assert_equal true, schema.catalog[:image][:required]
    assert_includes schema.validate({}), "image is required"
    assert_empty schema.validate(image: "/images/hero.jpg")
    assert_empty schema.validate(image: "https://example.com/hero.jpg")
    assert_empty schema.validate(image: "11111111-2222-3333-4444-555555555555")
    assert(schema.validate(image: "javascript:alert(1)").any? { |error| error.include?("image") })
  end

  def test_attachment_upgrade_remap_and_resolve_urls
    schema = RecordingStudioPages::FieldSchema.new(
      image: { type: :attachment, kind: :image },
      items: {
        type: :list,
        item: { name: :string, image: { type: :attachment, kind: :image } }
      }
    )

    upgraded = schema.upgrade_legacy_attachments(
      image_url: "/images/hero.jpg",
      items: [{ name: "One", image_url: "https://example.com/logo.png" }]
    )
    read = schema.read(upgraded)

    assert_equal "/images/hero.jpg", read["image"]
    assert_equal "https://example.com/logo.png", read.dig("items", 0, "image")
    refute read.key?("image_url")

    mapping = { "old-id" => "new-id" }
    remapped = schema.remap_attachments({ "image" => "old-id", "items" => [{ "name" => "One", "image" => "old-id" }] }, mapping)
    assert_equal "new-id", remapped["image"]
    assert_equal "new-id", remapped.dig("items", 0, "image")

    resolved = schema.resolve_attachments(
      { "image" => "/images/hero.jpg", "items" => [{ "name" => "One", "image" => "https://example.com/logo.png" }] },
      recording: nil
    )
    assert_equal "/images/hero.jpg", resolved["image"]
    assert_equal "https://example.com/logo.png", resolved.dig("items", 0, "image")
  end
end
