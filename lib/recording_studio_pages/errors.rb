# frozen_string_literal: true

module RecordingStudioPages
  class Error < StandardError; end
  class DuplicateRegistration < Error; end
  class UnknownSectionType < Error; end
  class UnknownCtaType < Error; end
  class UnknownTemplate < Error; end
  class InvalidSectionPayload < Error; end
  class UnpublishedPage < Error; end
end
