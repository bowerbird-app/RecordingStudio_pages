# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class TopNavComponent < ViewComponent::Base
      # Flatpack TopNav is sticky in document flow, so a Menu above a
      # fullscreen hero would otherwise sit in its own band and push the
      # image down. Overlay takes the bar out of flow and sits it on the
      # photo. Ghost buttons over a photo need a top scrim (taste).
      OVERLAY_TOKENS = {
        "--top-nav-background-color" => "transparent",
        "--top-nav-item-icon-color" => "white",
        "--top-nav-item-hover-text-color" => "white",
        "--top-nav-item-hover-background-color" => "rgb(255 255 255 / 0.12)",
        "--button-ghost-text-color" => "white",
        "--button-ghost-hover-text-color" => "white",
        "--button-ghost-hover-background-color" => "rgb(255 255 255 / 0.12)",
        "--button-ghost-border-color" => "transparent",
        "--button-primary-background-color" => "white",
        "--button-primary-text-color" => "oklch(0.25 0.01 80)",
        "--button-primary-hover-background-color" => "oklch(0.96 0.01 80)",
        "--button-primary-border-color" => "transparent",
        "--surface-background-color" => "oklch(0.22 0.02 80)",
        "--surface-content-color" => "white",
        "--surface-border-color" => "rgb(255 255 255 / 0.14)"
      }.freeze

      def initialize(rendered:, overlay: false)
        @rendered = rendered
        @overlay = overlay
      end

      def call
        return if empty?
        return render_nav unless overlay?

        helpers.content_tag(:div, **overlay_wrap_attributes) do
          helpers.content_tag(
            :div,
            class: "bg-gradient-to-b from-black/50 to-transparent pb-10",
            style: overlay_token_style
          ) { render_nav }
        end
      end

      private

      def render_nav
        render FlatPack::TopNav::Component.new(mobile_menu_label: "More") do |nav|
          nav.left { brand } if brand?
          nav.center { links } if links?
          nav.right(always_display: true) { join } if join?
        end
      end

      def overlay_wrap_attributes
        {
          class: "sticky top-0 z-20 overflow-visible",
          style: "height: 0",
          data: { pages_menu_overlay: true }
        }
      end

      def overlay_token_style
        OVERLAY_TOKENS.map { |name, value| "#{name}: #{value}" }.join("; ")
      end

      def overlay?
        @overlay
      end

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
