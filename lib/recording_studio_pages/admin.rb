# frozen_string_literal: true

module RecordingStudioPages
  module Admin
    def self.register!
      return unless defined?(RecordingStudioAdmin)

      RecordingStudioAdmin.register_widget(PublishedPagesWidget)
      RecordingStudioAdmin.register_widget(DraftPagesWidget)
      RecordingStudioAdmin.register_screen(PagesScreen)
      RecordingStudioAdmin.register_resource(PagesResource)
      RecordingStudioAdmin.register_section(PagesSection)
    end

    class PagesSection < RecordingStudioAdmin::Section
      key "pages"
      icon :document_text
      title "Pages"
      subtitle "Compose public pages from registered sections"
      blast_radius :site
      link :pages, text: "View pages", url: ->(_context) { "/recording_studio_pages/admin/pages" },
                   style: :secondary
      link :new_page, text: "New page", url: ->(_context) { "/recording_studio_pages/admin/pages/new" },
                      style: :primary
      widget "widgets.pages.published_pages", view_variant: :compact
      widget "widgets.pages.draft_pages", view_variant: :compact
    end

    class PagesScreen < RecordingStudioAdmin::Screen
      key "pages"
      title "Pages"
      subtitle "Every page is a recording. Sections hang under it."
      blast_radius :site
      button :new_page, text: "New page", url: ->(_context) { "/recording_studio_pages/admin/pages/new" },
                        style: :primary

      query do |_context|
        RecordingStudio::Recording.where(recordable_type: "RecordingStudioPages::Page", trashed_at: nil)
                                  .includes(:recordable)
                                  .order(updated_at: :desc)
      end

      table do
        column :title, value: ->(recording) { recording.recordable&.title }
        column :homepage, value: ->(recording) { recording.recordable&.homepage? ? "Home" : "" }
        column :updated_at
      end
    end

    class PagesResource < RecordingStudioAdmin::Resource
      key "pages"
      section "pages"

      action :open,
             text: "Open",
             icon: "eye",
             url: ->(recording, _context) { "/recording_studio_pages/admin/pages/#{recording.id}" }
    end

    PublishedPagesWidget = RecordingStudioAdmin::Widget.new("widgets.pages.published_pages") do
      title "Live pages"
      info "Pages RS Publishable currently treats as public."
      blast_radius :site
      value do |_context|
        RecordingStudio::Recording.where(recordable_type: "RecordingStudioPages::Page", trashed_at: nil)
                                  .includes(:recordable)
                                  .count { |recording| recording.respond_to?(:currently_published?) && recording.currently_published? }
      end
    end

    DraftPagesWidget = RecordingStudioAdmin::Widget.new("widgets.pages.draft_pages") do
      title "Drafts"
      info "Pages that exist but are not live yet."
      blast_radius :site
      value do |_context|
        RecordingStudio::Recording.where(recordable_type: "RecordingStudioPages::Page", trashed_at: nil)
                                  .includes(:recordable)
                                  .count { |recording| !recording.respond_to?(:currently_published?) || !recording.currently_published? }
      end
    end
  end
end
