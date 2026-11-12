# frozen_string_literal: true

require_relative "errors"
require_relative "lookup"

module RecordingStudioPages
  module Api
    module PageResource
      module PageFields
        module_function

        def call(context)
          Lookup.symbolized_payload(context).slice(:title, :homepage)
        end
      end

      class Create
        def self.call(context)
          parent = Lookup.parent_recording(context)
          context.access_grant.authorize!(recording: parent, role: :edit)
          attributes = PageFields.call(context)
          page = Errors.unwrap(Services::CreatePage.call(parent_recording: parent, actor: context.actor, **attributes))
          { json: Lookup.serialize(page, context), status: :created }
        end
      end

      class Update
        def self.call(context)
          page = context.scoped_recordings.find_by(id: context.id)
          if page.nil? || page.recordable_type != Lookup::PAGE_TYPE
            raise ::RecordingStudioApi::NotFoundError, "Resource was not found in this API scope"
          end

          context.access_grant.authorize!(recording: page, role: :edit)
          attributes = PageFields.call(context)
          updated = Errors.unwrap(Services::RevisePage.call(page_recording: page, actor: context.actor, **attributes))
          { json: Lookup.serialize(updated, context) }
        end
      end
    end
  end
end
