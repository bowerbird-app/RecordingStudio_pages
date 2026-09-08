Rails.application.routes.draw do
  devise_for :users

  get "/recording_studio", to: redirect("/studio"), as: nil
  mount RecordingStudio::Engine, at: "/recording_studio"
  mount RecordingStudioRootSwitchable::Engine, at: "/recording_studio_root_switchable"
  mount RecordingStudioAccessible::Engine, at: "/admin/access"
  mount RecordingStudioAttachable::Engine, at: "/recording_studio_attachable"
  mount RecordingStudioPages::Engine, at: "/recording_studio_pages"
  mount RecordingStudioDuplicatable::Engine, at: "/recording_studio_duplicatable"
  mount RecordingStudioPublishable::Engine, at: "/"
  recording_studio_admin_for :admin, at: "/admin", root_section: :pages

  get "up" => "rails/health#show", as: :rails_health_check

  get "docs/install", to: "docs#install", as: :docs_install
  get "docs/config", to: "docs#configuration", as: :docs_config
  get "docs/recordable_types", to: "docs#recordable_types", as: :docs_recordable_types
  get "docs/recordings_tree", to: "docs#recordings_tree", as: :docs_recordings_tree
  get "docs/gem_views", to: "docs#gem_views", as: :docs_gem_views
  get "docs/methods", to: "docs#methods", as: :docs_methods

  get "/studio", to: "home#index", as: :studio
  get "/start", to: "starts#show", as: :start

  root to: "recording_studio_pages/homepages#show"
end
