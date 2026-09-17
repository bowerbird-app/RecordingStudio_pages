# frozen_string_literal: true

module RecordingStudioPages
  module Admin
    SECTION_KEY = "pages"
    SCREEN_KEY = "pages"
    ENGINE_MOUNT_PATH = "/recording_studio_pages"

    def self.register!
      return unless defined?(RecordingStudioAdmin)

      RecordingStudioAdmin.register_widget(PublishedPagesWidget)
      RecordingStudioAdmin.register_widget(DraftPagesWidget)
      RecordingStudioAdmin.register_screen(PagesScreen)
      RecordingStudioAdmin.register_resource(PagesResource)
      RecordingStudioAdmin.register_section(PagesSection)
    end

    def self.screen_path(status: nil)
      append_status_query("#{admin_mount_path}/screens/#{SCREEN_KEY}", status)
    end

    def self.screen_path_for(context, status: nil)
      append_status_query(context.admin_screen_path(SCREEN_KEY), status)
    end

    def self.append_status_query(path, status)
      return path if status.blank?

      query = { status: status }.to_query
      "#{path}?#{query}"
    end
    private_class_method :append_status_query

    def self.new_page_path
      "#{ENGINE_MOUNT_PATH}/admin/pages/new"
    end

    def self.admin_mount_path
      return "/admin" unless defined?(RecordingStudioAdmin)

      RecordingStudioAdmin.configuration.default_mount_path.to_s.chomp("/")
    end

    class PagesSection < RecordingStudioAdmin::Section
      key SECTION_KEY
      icon :document_text
      title "Pages"
      subtitle "Compose public pages from registered sections"
      blast_radius :site
      link :new_page, text: "Page", url: ->(_context) { RecordingStudioPages::Admin.new_page_path },
                      style: :primary
      link :pages, text: "View all", url: ->(context) { context.admin_screen_path(SCREEN_KEY) },
                   style: :secondary
      widget "widgets.pages.published_pages", view_variant: :compact
      widget "widgets.pages.draft_pages", view_variant: :compact
    end

    class PagesScreen < RecordingStudioAdmin::Screen
      key SCREEN_KEY
      title "Pages"
      subtitle "Compose public pages from sections."
      blast_radius :site
      button :new_page, text: "Page", url: ->(_context) { RecordingStudioPages::Admin.new_page_path },
                        style: :primary

      STATUS_FILTER = lambda { |relation, value, _context|
        RecordingStudioPages::Composition.filter_page_recordings_by_status(relation, value)
      }
      STATUS_VALUE = ->(recording, _context) { RecordingStudioPages::Composition.page_status(recording) }
      STATUS_BADGE = lambda { |_recording, _context, value|
        {
          text: value,
          style: RecordingStudioPages::Composition.page_status_badge_style(value),
          size: :sm
        }
      }

      query do |_context|
        RecordingStudio::Recording.where(recordable_type: "RecordingStudioPages::Page", trashed_at: nil)
                                  .includes(:recordable)
                                  .order(updated_at: :desc)
      end

      table do
        default_sort :updated_at
        filter :status,
               options: RecordingStudioPages::Composition::STATUS_OPTIONS,
               placeholder: "Status",
               apply: STATUS_FILTER
        column :title, title: "Page", sortable: false,
                       value: ->(recording, _context) { recording.recordable&.title }
        column :status, title: "Status", sortable: false, display: :badge,
                        display_options: STATUS_BADGE, value: STATUS_VALUE
        column :homepage, title: "Home", sortable: false,
                          value: ->(recording, _context) { recording.recordable&.homepage? ? "Home" : "" }
        column :updated_at
      end
    end

    class PagesResource < RecordingStudioAdmin::Resource
      key SCREEN_KEY
      section SECTION_KEY

      action :open,
             text: "Open",
             icon: "eye",
             url: ->(recording, _context) { "#{ENGINE_MOUNT_PATH}/admin/pages/#{recording.id}" }
    end

    PublishedPagesWidget = RecordingStudioAdmin::Widget.new("widgets.pages.published_pages") do
      title "Live pages"
      info "Pages that are live on the public site."
      blast_radius :site
      value do |_context|
        RecordingStudioPages::Composition.published_pages_count
      end
      link_to { |context| RecordingStudioPages::Admin.screen_path_for(context) }
      link_label "Pages"
    end

    DraftPagesWidget = RecordingStudioAdmin::Widget.new("widgets.pages.draft_pages") do
      title "Drafts"
      info "Pages that exist but are not live yet."
      blast_radius :site
      value do |_context|
        RecordingStudioPages::Composition.draft_pages_count
      end
      link_to do |context|
        RecordingStudioPages::Admin.screen_path_for(context, status: RecordingStudioPages::Composition::STATUS_DRAFT)
      end
      link_label "Drafts"
    end
  end
end
