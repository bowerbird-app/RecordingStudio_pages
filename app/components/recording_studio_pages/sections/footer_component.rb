# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class FooterComponent < ViewComponent::Base
      BAND_CLASS = [
        "w-full border-t border-[var(--surface-border-color)]",
        "bg-[var(--surface-muted-background-color)]"
      ].join(" ").freeze
      INNER_CLASS = [
        "mx-auto flex w-full max-w-6xl flex-col gap-4 px-6 py-8",
        "sm:flex-row sm:items-center sm:justify-between"
      ].join(" ").freeze

      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        return if empty?

        helpers.content_tag(:footer, class: BAND_CLASS) do
          helpers.content_tag(:div, helpers.safe_join([identity, link_row].compact), class: INNER_CLASS)
        end
      end

      private

      def empty?
        name.blank? && note.blank? && link_buttons.empty?
      end

      def identity
        return if name.blank? && note.blank?

        helpers.content_tag(:div, class: "flex min-w-0 flex-col gap-1") do
          helpers.safe_join([name_line, note_line].compact)
        end
      end

      def name_line
        return if name.blank?

        helpers.content_tag(:p, name, class: "font-medium text-[var(--surface-content-color)]")
      end

      def note_line
        return if note.blank?

        helpers.content_tag(:p, note, class: "text-sm text-[var(--surface-muted-content-color)]")
      end

      def link_row
        buttons = link_buttons
        return if buttons.empty?

        helpers.content_tag(:div, helpers.safe_join(buttons), class: "flex flex-wrap items-center gap-2")
      end

      def link_buttons
        link_items.filter_map { |item| link_button(item) }
      end

      def link_button(item)
        text = item["text"].to_s
        url = item["url"].to_s
        return if text.blank? || url.blank?

        render FlatPack::Button::Component.new(text: text, href: url, style: :ghost, size: :sm)
      end

      def link_items
        Array(content["links"])
      end

      def name
        content["name"].to_s.presence
      end

      def note
        content["note"].to_s.presence
      end

      def content
        @rendered.content
      end
    end
  end
end
