# frozen_string_literal: true

module XXXDownload
  module Net
    class ZtodDownloadLinks < AlgoliaDownloadLinks
      BASE_URL = Constants::ZTOD_BASE_URL

      def initialize
        super(BASE_URL)
      end
    end
  end
end
