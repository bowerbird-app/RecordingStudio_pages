# frozen_string_literal: true

module RecordingStudioPages
  module Admin
    SECTION_KEY = "pages"
    SCREEN_KEY = "pages"
    RESOURCE_KEY = "pages"

    def self.register!
      return unless defined?(RecordingStudioAdmin)

      RecordingStudioAdmin.register_widget(PublishedPagesWidget)
      RecordingStudioAdmin.register_widget(DraftPagesWidget)
      RecordingStudioAdmin.register_screen(PagesScreen)
      RecordingStudioAdmin.register_resource(PagesResource)
      RecordingStudioAdmin.register_section(PagesSection)
    end

    def self.screen_path
      "#{admin_mount_path}/screens/#{SCREEN_KEY}"
    end

    def self.section_path
      "#{admin_mount_path}/sections/#{SECTION_KEY}"
    end

    def self.editor_path(recording_id)
      "#{engine_mount_path}/admin/pages/#{recording_id}"
    end

    def self.new_page_path
      "#{engine_mount_path}/admin/pages/new"
    end

    def self.admin_mount_path
      return "/admin" unless defined?(RecordingStudioAdmin)

      RecordingStudioAdmin.configuration.default_mount_path.to_s.chomp("/")
    end

    def self.engine_mount_path
      "/recording_studio_pages"
    end

    class PagesSection < RecordingStudioAdmin::Section
      key SECTION_KEY
      icon :document_text
      title "Pages"
      subtitle "Compose public pages from registered sections"
      blast_radius :site
      link :pages, text: "Pages", url: ->(context) { context.admin_screen_path(SCREEN_KEY) },
                   style: :secondary
      link :new_page, text: "New", url: ->(_context) { RecordingStudioPages::Admin.new_page_path },
                      style: :primary
      widget "widgets.pages.published_pages", view_variant: :compact
      widget "widgets.pages.draft_pages", view_variant: :compact
    end

    class PagesScreen < RecordingStudioAdmin::Screen
      key SCREEN_KEY
      title "Pages"
      subtitle "Compose a public page from registered sections."
      blast_radius :site
      button :new_page, text: "New", url: ->(_context) { RecordingStudioPages::Admin.new_page_path },
                        style: :primary

      query do |_context|
        RecordingStudio::Recording.where(recordable_type: "RecordingStudioPages::Page", trashed_at: nil)
                                  .includes(:recordable)
                                  .order(updated_at: :desc)
      end

      table do
        title "Pages"
        hide_columns_button
        column :title, title: "Page", value: ->(recording) { recording.recordable&.title }
        column :homepage, title: "Home", value: ->(recording) { recording.recordable&.homepage? ? "Home" : "" }
        column :updated_at, title: "Updated"
        admin_action "pages.open"
      end
    end

    class PagesResource < RecordingStudioAdmin::Resource
      key RESOURCE_KEY
      section SECTION_KEY

      action :open,
             text: "Open",
             icon: "eye",
             required_role: :view,
             url: ->(recording, _context) { RecordingStudioPages::Admin.editor_path(recording.id) }
      action :edit,
             text: "Edit",
             required_role: :edit,
             url: ->(recording, _context) { "#{RecordingStudioPages::Admin.editor_path(recording.id)}/edit" }
    end

    PublishedPagesWidget = RecordingStudioAdmin::Widget.new("widgets.pages.published_pages") do
      title "Live pages"
      info "Pages that are live on the public site."
      blast_radius :site
      link_to { |_context| RecordingStudioPages::Admin.screen_path }
      value do |_context|
        RecordingStudioPages::Composition.published_pages_count
      end
    end

    DraftPagesWidget = RecordingStudioAdmin::Widget.new("widgets.pages.draft_pages") do
      title "Drafts"
      info "Pages that exist but are not live yet."
      blast_radius :site
      link_to { |_context| RecordingStudioPages::Admin.screen_path }
      value do |_context|
        RecordingStudioPages::Composition.draft_pages_count
      end
    end
  end
end
