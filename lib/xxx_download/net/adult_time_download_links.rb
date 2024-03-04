# frozen_string_literal: true

module XXXDownload
  module Net
    class AdultTimeDownloadLinks < AlgoliaDownloadLinks
      BASE_URL = Constants::ADULTTIME_BASE_URL

      def initialize
        super(BASE_URL)
      end
    end
  end
end
