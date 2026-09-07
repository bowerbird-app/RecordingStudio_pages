# frozen_string_literal: true

class CreateRecordingStudioPagesSections < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_pages_sections, id: :uuid do |t|
      t.string :section_type, null: false
      t.jsonb :content, null: false, default: {}
      t.jsonb :settings, null: false, default: {}
      t.boolean :enabled, null: false, default: true
      t.datetime :created_at, null: false
    end

    add_index :recording_studio_pages_sections, :section_type
    add_index :recording_studio_pages_sections, :enabled
  end
end
