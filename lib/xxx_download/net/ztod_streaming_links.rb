# frozen_string_literal: true

module XXXDownload
  module Net
    class ZTODStreamingLinks < AlgoliaStreamingLinks
      def initialize(config)
        super(config, Constants::ADULTTIME_BASE_URL)
      end
    end
  end
end
