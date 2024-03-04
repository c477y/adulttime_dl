# frozen_string_literal: true

module XXXDownload
  module Net
    class BlowpassDownloadLinks < AlgoliaDownloadLinks
      BASE_URL = Constants::BLOW_PASS_BASE_URL

      def initialize
        super(BASE_URL)
      end
    end
  end
end
