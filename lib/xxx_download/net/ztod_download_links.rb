# frozen_string_literal: true

module XXXDownload
  module Net
    class ZtodDownloadLinks < AlgoliaDownloadLinks
      BASE_URL = Constants::ZTOD_BASE_URL

      # @param [Data::Config] config
      def initialize(config)
        super(config, BASE_URL)
      end
    end
  end
end
