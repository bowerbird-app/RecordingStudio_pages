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

    def self.install_helpers!
      return unless defined?(RecordingStudioAdmin::ApplicationController)
      return unless RecordingStudioAdmin::ApplicationController.respond_to?(:helper)

      controller = RecordingStudioAdmin::ApplicationController
      controller.helper RecordingStudioPages::ApplicationHelper
      if defined?(RecordingStudioPublishable::ApplicationHelper)
        controller.helper RecordingStudioPublishable::ApplicationHelper
      end
      install_mounted_helpers!(controller)
    end

    def self.install_mounted_helpers!(controller)
      return unless defined?(Rails.application)
      return unless Rails.application.respond_to?(:routes)

      mounted = Rails.application.routes.mounted_helpers
      controller.include mounted
      controller.helper mounted
    end
    private_class_method :install_mounted_helpers!

    def self.screen_path(status: nil, home_page: nil)
      append_list_query("#{admin_mount_path}/screens/#{SCREEN_KEY}", status: status, home_page: home_page)
    end

    def self.screen_path_for(context, status: nil, home_page: nil)
      append_list_query(context.admin_screen_path(SCREEN_KEY), status: status, home_page: home_page)
    end

    def self.append_list_query(path, status: nil, home_page: nil)
      query = { status: status, home_page: home_page }.compact_blank
      return path if query.blank?

      "#{path}?#{query.to_query}"
    end
    private_class_method :append_list_query

    def self.new_page_path(anchor_url: nil)
      merge_anchor_url("#{ENGINE_MOUNT_PATH}/admin/pages/new", anchor_url)
    end

    def self.page_path(recording, anchor_url: nil)
      merge_anchor_url("#{ENGINE_MOUNT_PATH}/admin/pages/#{recording.id}", anchor_url)
    end

    def self.safe_anchor_url(value)
      href = value.to_s.strip
      return if href.empty?
      return href if href.start_with?("/") && !href.start_with?("//")

      nil
    end

    def self.merge_anchor_url(path, anchor_url)
      href = safe_anchor_url(anchor_url)
      return path if href.blank?

      uri = URI.parse(path)
      query = Rack::Utils.parse_nested_query(uri.query)
      query["anchor_url"] ||= href
      uri.query = query.to_query.presence
      uri.to_s
    rescue URI::InvalidURIError
      path
    end

    def self.admin_mount_path
      return "/admin" unless defined?(RecordingStudioAdmin)

      RecordingStudioAdmin.configuration.default_mount_path.to_s.chomp("/")
    end

    def self.render_publishable_actions(recording, context)
      view = context.respond_to?(:view_context) ? context.view_context : nil
      return unless view
      return unless view.respond_to?(:render_publishable_quick_actions)

      view.render_publishable_quick_actions(recording)
    end

    def self.public_page_path(recording)
      return unless defined?(RecordingStudioPublishable::PageLink)

      link = RecordingStudioPublishable::PageLink.for(recording: recording, preview_href: "")
      return if link.blank? || link.text != "View"

      link.href.presence
    end

    def self.render_page_title(recording, context)
      title = recording.recordable&.title
      href = public_page_path(recording)
      view = context.respond_to?(:view_context) ? context.view_context : nil
      return title unless href.present? && view.respond_to?(:render)

      view.render(public_page_link(href)) { title }
    end

    def self.public_page_link(href)
      FlatPack::Link::Component.new(href: href, target: "_blank", data: { turbo: false })
    end
    private_class_method :public_page_link

    class PagesSection < RecordingStudioAdmin::Section
      key SECTION_KEY
      icon :document_text
      title "Pages"
      subtitle "Compose public pages from registered sections"
      blast_radius :site
      link :new_page, text: "Page",
                      url: ->(_context) { RecordingStudioPages::Admin.new_page_path(anchor_url: RecordingStudioPages::Admin.admin_mount_path) },
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
      button :new_page, text: "Page",
                        url: ->(context) { RecordingStudioPages::Admin.new_page_path(anchor_url: context.admin_screen_path(SCREEN_KEY)) },
                        style: :primary

      STATUS_FILTER = lambda { |relation, value, _context|
        RecordingStudioPages::Composition.filter_page_recordings_by_status(relation, value)
      }
      HOMEPAGE_FILTER = lambda { |relation, value, _context|
        RecordingStudioPages::Composition.filter_page_recordings_by_homepage(relation, value)
      }
      STATUS_ACTIONS = lambda { |recording, context|
        RecordingStudioPages::Admin.render_publishable_actions(recording, context)
      }
      TITLE_CELL = lambda { |recording, context|
        RecordingStudioPages::Admin.render_page_title(recording, context)
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
               apply: STATUS_FILTER
        filter :home_page,
               options: RecordingStudioPages::Composition::HOMEPAGE_OPTIONS,
               apply: HOMEPAGE_FILTER
        column :title, title: "Page", sortable: false, value: TITLE_CELL
        column :homepage, title: "Home", sortable: false,
                          value: ->(recording, _context) { recording.recordable&.homepage? ? "Home" : "" }
        column :updated_at
        column :status, title: "Status", sortable: false, value: STATUS_ACTIONS
        admin_action SCREEN_KEY, :edit
        admin_action SCREEN_KEY, :trash
      end
    end

    class PagesResource < RecordingStudioAdmin::Resource
      key SCREEN_KEY
      section SECTION_KEY
      blast_radius :site

      action :edit,
             text: "Edit",
             icon: "pencil-square",
             required_role: :view,
             blast_radius: :site,
             url: ->(recording, context) { RecordingStudioPages::Admin.page_path(recording, anchor_url: context.admin_screen_path(SCREEN_KEY)) }
      action :trash,
             text: "Trash",
             icon: "trash",
             method: :delete,
             confirm: "Trash this page?",
             destructive: true,
             required_role: :edit,
             blast_radius: :site,
             url: ->(recording, _context) { RecordingStudioPages::Admin.page_path(recording) }
    end

    PublishedPagesWidget = RecordingStudioAdmin::Widget.new("widgets.pages.published_pages") do
      title "Published"
      info "Pages that are on the public site."
      blast_radius :site
      value do |_context|
        RecordingStudioPages::Composition.published_pages_count
      end
      link_to do |context|
        RecordingStudioPages::Admin.screen_path_for(
          context,
          status: RecordingStudioPages::Composition::STATUS_PUBLISHED
        )
      end
      link_label "Published"
    end

    DraftPagesWidget = RecordingStudioAdmin::Widget.new("widgets.pages.draft_pages") do
      title "Drafts"
      info "Pages that are still a draft."
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
