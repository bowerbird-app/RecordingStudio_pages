# frozen_string_literal: true

module RecordingStudioPages
  module ApplicationHelper
    def recording_studio_pages_flash
      render "recording_studio_pages/flash"
    end

    def recording_studio_pages_nav(title:, back_url: nil)
      if respond_to?(:recording_studio_pages_page_nav)
        recording_studio_pages_page_nav(title: title, back_url: back_url)
      elsif respond_to?(:recording_studio_page_nav)
        recording_studio_page_nav(title: title, page_nav_back_url: back_url)
      end
    end

    def pages_attachable_routes
      return unless defined?(RecordingStudioAttachable)
      return recording_studio_attachable if respond_to?(:recording_studio_attachable)
      return unless respond_to?(:main_app)

      main_app.recording_studio_attachable if main_app.respond_to?(:recording_studio_attachable)
    end

    def pages_setting_visible?(spec, settings:, content:)
      show_when = spec[:show_when]
      return true if show_when.blank?

      rules = show_when.to_h.symbolize_keys
      return false if rules[:variant].present? && settings["variant"].to_s != rules[:variant].to_s
      return false if rules[:image] && content["image"].blank?

      true
    end

    def pages_colour_preview(key, settings)
      row = COLOUR_PREVIEWS[key.to_s]
      return "#ffffff" unless row

      values = settings.to_h.stringify_keys
      if values["variant"].to_s == "fullscreen_image"
        values["background"].to_s == "light" ? row.fetch("light") : row.fetch("dark")
      else
        row.fetch("plain")
      end
    end

    COLOUR_PREVIEWS = {
      "eyebrow_color" => { "dark" => "#cccccc", "light" => "#555555", "plain" => "#6b7280" },
      "title_color" => { "dark" => "#ffffff", "light" => "#222222", "plain" => "#171717" },
      "body_color" => { "dark" => "#cccccc", "light" => "#555555", "plain" => "#6b7280" }
    }.freeze
    private_constant :COLOUR_PREVIEWS
  end
end
