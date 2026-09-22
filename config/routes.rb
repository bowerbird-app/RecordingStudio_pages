# frozen_string_literal: true

RecordingStudioPages::Engine.routes.draw do
  get "/", to: "homepages#show", as: :homepage

  namespace :admin do
    resources :pages, only: %i[index new create show edit update destroy] do
      resources :sections, only: %i[new create edit update destroy] do
        patch :reorder, on: :collection
        post :toggle, on: :member
        post :duplicate, on: :member
      end
    end
  end
end
