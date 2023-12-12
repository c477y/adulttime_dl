# frozen_string_literal: true

module AdultTimeDL
  module Net
    class AlgoliaDownloadLinks < Base
      include HTTParty

      # @param [Data::Config] config
      def initialize(config, base_uri)
        @cookie = config.cookie
        @config = config
        self.class.base_uri(base_uri)
        self.class.logger AdultTimeDL.logger, :debug
        super()
      end

      # @param [Data::Scene] scene_data
      # @return [String, NilClass]
      def fetch(scene_data)
        path = SCENE_DOWNLOAD_LINK
               .gsub("%clip_id%", scene_data.clip_id.to_s)
               .gsub("%resolution%", scene_data.available_resolution(config.quality))
        response = self.class.get(path, follow_redirects: false, headers: headers)
        case response.code
        when 302 then check_download_link!(response)
        when 404 then nil
        else handle_response!(response)
        end
      end

      private

      attr_reader :cookie, :config

      SCENE_DOWNLOAD_LINK = "/movieaction/download/%clip_id%/%resolution%/mp4"

      def headers
        default_headers.merge(
          {
            "X-Requested-With" => "XMLHttpRequest",
            "Cookie" => cookie
          }
        )
      end

      def check_download_link!(response)
        if response.headers["location"].include?("/login")
          endpoint = "#{response.request.base_uri}#{response.request.path}"
          raise RedirectedError.new(endpoint: endpoint,
                                    code: response.code,
                                    body: response.parsed_response,
                                    headers: response.headers)
        else
          response.headers["location"]
        end
      end
    end
  end
end
