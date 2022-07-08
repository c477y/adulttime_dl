# frozen_string_literal: true

module AdultTimeDL
  module Net
    class AdultTimeDownloadLinks < AlgoliaDownloadLinks
      BASE_URL = Constants::ADULTTIME_BASE_URL

      # @param [Data::Config] config
      def initialize(config)
        super(config, BASE_URL)
      end
    end
  end
end
