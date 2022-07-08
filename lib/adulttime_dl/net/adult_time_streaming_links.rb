# frozen_string_literal: true

module AdultTimeDL
  module Net
    class AdultTimeStreamingLinks < AlgoliaStreamingLinks
      def initialize(config)
        super(config, Constants::ADULTTIME_BASE_URL)
      end
    end
  end
end
