# frozen_string_literal: true

module XXXDownload
  module Net
    class AlgoliaDownloadLinks < Base
      include AlgoliaUtils

      TAG = "ALGOLIA_DOWNLOAD_LINKS"

      def initialize
        super()
        self.class.base_uri site_base_uri
        self.class.headers "X-Requested-With" => "XMLHttpRequest"
        self.class.follow_redirects false
        self.class.headers "Cookie" => XXXDownload.config.cookie
      end

      # @param [Data::Scene] scene_data
      # @return [String, NilClass]
      def fetch(scene_data)
        path = SCENE_DOWNLOAD_LINK
               .gsub("%clip_id%", scene_data.clip_id.to_s)
               .gsub("%resolution%", scene_data.available_resolution(XXXDownload.config.quality))
        response = handle_response!(handle_errors: false) { self.class.get(path) }
        handle_api_error(response)
      rescue RedirectedError # Redirection is expected for download links and are technically not errors
        check_download_link(scene_data, response)
      rescue NotFoundError => e
        XXXDownload.logger.warn "[#{TAG}] Download link not found for #{scene_data.title}"
        XXXDownload.logger.debug e.message
        nil
      end

      def authenticator
        @authenticator ||= SiteAuthenticator.new(site_base_uri)
      end

      private

      SCENE_DOWNLOAD_LINK = "/movieaction/download/%clip_id%/%resolution%/mp4"

      def check_download_link(scene_data, response)
        if response.headers["location"].include?("/login")
          cookie = authenticator.request_cookie(force_request: true) do |cookies|
            cookies.any? { |c| c[:name] == "activeMemberValidator" && c[:value]&.to_i == 1 } &&
              cookies.any? { |c| c[:name] == "autologin_userid" }
          end
          self.class.headers "Cookie" => cookie
          fetch(scene_data)
        else
          response.headers["location"]
        end
      end
    end
  end
end
