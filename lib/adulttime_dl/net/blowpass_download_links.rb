# frozen_string_literal: true

module AdultTimeDL
  module Net
    class BlowPassDownloadLinks < AlgoliaDownloadLinks
      BASE_URL = Constants::BLOW_PASS_BASE_URL

      # @param [Data::Config] config
      def initialize(config)
        super(config, BASE_URL)
      end
    end
  end
end

