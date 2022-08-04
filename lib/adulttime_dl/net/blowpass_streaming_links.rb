# frozen_string_literal: true

module AdultTimeDL
  module Net
    class BlowPassStreamingLinks < AlgoliaStreamingLinks
      def initialize(config)
        super(config, Constants::BLOW_PASS_BASE_URL)
      end
    end
  end
end
