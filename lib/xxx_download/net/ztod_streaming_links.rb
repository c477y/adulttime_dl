# frozen_string_literal: true

module XXXDownload
  module Net
    class ZtodStreamingLinks < AlgoliaStreamingLinks
      def initialize(config)
        super(config, Constants::ADULTTIME_BASE_URL)
      end
    end
  end
end
