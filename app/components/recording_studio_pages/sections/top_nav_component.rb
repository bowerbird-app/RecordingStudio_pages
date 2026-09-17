# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class TopNavComponent < ViewComponent::Base
      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        return if empty?

        render FlatPack::TopNav::Component.new(mobile_menu_label: "More") do |nav|
          nav.left { brand } if brand?
          nav.center { links } if links?
          nav.right(always_display: true) { join } if join?
        end
      end

      private

      def empty?
        !brand? && !links? && !join?
      end

      def brand?
        brand.present?
      end

      def links?
        links.present?
      end

      def join?
        join.present?
      end

      def brand
        return @brand if defined?(@brand)

        pieces = [mark, name_button].compact
        @brand = if pieces.empty?
                   nil
                 else
                   helpers.content_tag(:div, helpers.safe_join(pieces), class: "flex items-center gap-2")
                 end
      end

      def mark
        return if mark_url.blank?

        helpers.image_tag(mark_url, alt: brand_name.presence || "Mark", class: "h-8 w-auto object-contain")
      end

      def name_button
        return if brand_name.blank?

        render FlatPack::Button::Component.new(
          text: brand_name,
          href: home_url,
          style: :ghost,
          size: :md
        )
      end

      def links
        buttons = link_items.filter_map { |item| link_button(item) }
        return if buttons.empty?

        helpers.content_tag(:div, helpers.safe_join(buttons), class: "flex items-center gap-2")
      end

      def link_button(item)
        text = item["text"].to_s
        url = item["url"].to_s
        return if text.blank? || url.blank?

        render FlatPack::Button::Component.new(
          text: text,
          href: url,
          style: :ghost,
          size: :md
        )
      end

      def join
        return @join if defined?(@join)

        @join = RecordingStudioPages::CtaRenderer.call(self, content["cta"])
      end

      def link_items
        Array(content["links"])
      end

      def brand_name
        content["name"].to_s.presence
      end

      def mark_url
        content["image"].to_s.presence
      end

      def home_url
        RecordingStudioPages.homepage_path
      end

      def content
        @rendered.content
      end
    end
  end
end
