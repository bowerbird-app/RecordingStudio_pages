# frozen_string_literal: true

class CreateRecordingStudioPagesPages < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_pages_pages, id: :uuid do |t|
      t.string :title, null: false
      t.boolean :homepage, null: false, default: false
      t.string :template_key
      t.datetime :created_at, null: false
    end

    add_index :recording_studio_pages_pages, :homepage
    add_index :recording_studio_pages_pages, :template_key
  end
end
