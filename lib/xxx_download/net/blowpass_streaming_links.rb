# frozen_string_literal: true

module XXXDownload
  module Net
    class BlowpassStreamingLinks < AlgoliaStreamingLinks
      def initialize
        super(Constants::BLOW_PASS_BASE_URL)
      end
    end
  end
end
