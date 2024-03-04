# frozen_string_literal: true

module XXXDownload
  module Net
    class AdultTimeStreamingLinks < AlgoliaStreamingLinks
      def initialize
        super(Constants::ADULTTIME_BASE_URL)
      end
    end
  end
end
