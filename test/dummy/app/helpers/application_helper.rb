# frozen_string_literal: true

module ApplicationHelper
  include RecordingStudioUser::OmniauthHelper

  EXAMPLE_PAGE_ORDER = [
    "Home",
    "About",
    "Tonight",
    "Join",
    "Walk in",
    "Start from a URL"
  ].freeze

  EXAMPLE_PAGE_ICONS = {
    "Home" => :home,
    "About" => :information_circle,
    "Tonight" => :moon,
    "Join" => :user_plus,
    "Walk in" => :arrow_right_end_on_rectangle,
    "Start from a URL" => :link
  }.freeze

  def dummy_example_pages
    RecordingStudio::Recording.where(
      recordable_type: "RecordingStudioPages::Page",
      trashed_at: nil
    ).includes(:recordable).filter_map do |recording|
      href = dummy_example_page_path(recording)
      next if href.blank?

      title = recording.recordable&.title.to_s.strip
      next if title.blank?

      {
        title: title,
        href: href,
        icon: EXAMPLE_PAGE_ICONS.fetch(title, :document_text)
      }
    end.sort_by { |page| [EXAMPLE_PAGE_ORDER.index(page[:title]) || EXAMPLE_PAGE_ORDER.size, page[:title]] }
  end

  def dummy_example_page_path(recording)
    return unless recording.respond_to?(:currently_published?) && recording.currently_published?

    publishable_recording = recording.publishable_child_recording
    publishable = publishable_recording&.recordable
    return if publishable.blank? || publishable.slug.blank?

    "/pages/#{publishable_recording.id}/#{publishable.slug}"
  end

  def dummy_page_nav(title:, back_url: nil, back_label: "Home")
    recording_studio_page_nav(
      title: title,
      page_nav_back_url: back_url,
      page_nav_back_label: back_label
    )

    recording_studio_page_nav_right do
      concat recording_studio_root_switch_dropdown(style: :ghost, size: :md)
      concat render(
        FlatPack::Button::Component.new(
          text: "Sign out",
          style: :ghost,
          size: :md,
          href: main_app.destroy_user_session_path,
          method: :delete
        )
      )
    end
  end
end
