# frozen_string_literal: true

require_relative "errors"
require_relative "lookup"

module RecordingStudioPages
  module Api
    module SectionResource
      class Update
        def self.call(context)
          section = Lookup.find!(context, context.id, types: [Lookup::SECTION_TYPE])
          context.access_grant.authorize!(recording: section, role: :edit)
          updated = Errors.unwrap(Services::ReviseSection.call(**revise_arguments(section, context)))
          { json: Lookup.serialize(updated, context) }
        end

        def self.revise_arguments(section, context)
          {
            section_recording: section,
            content: kept_or(:content, context),
            settings: kept_or(:settings, context),
            actor: context.actor
          }
        end
        private_class_method :revise_arguments

        def self.kept_or(key, context)
          fields = Lookup.symbolized_payload(context)
          fields.key?(key) ? fields[key] : :keep
        end
        private_class_method :kept_or
      end
    end
  end
end
