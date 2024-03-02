# frozen_string_literal: true

module XXXDownload
  module Net
    module AlgoliaUtils
      SITE_LOOKUP = {
        "adulttime" => Constants::ADULTTIME_BASE_URL,
        "evilangel" => Constants::EVIL_ANGEL_BASE_URL,
        "ztod" => Constants::ZTOD_BASE_URL,
        "blowpass" => Constants::BLOW_PASS_BASE_URL
      }.freeze

      def non_member_base_url
        site_base_uri.gsub("members.", "www.")
      end

      def site_base_uri
        SITE_LOOKUP.fetch(config.site) do
          raise FatalError, "received unexpected site name #{config.site}"
        end
      end
    end
  end
end
