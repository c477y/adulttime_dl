# frozen_string_literal: true

module XXXDownload
  module Net
    # Deprecated. These provide no significant value compared to direct download
    class AlgoliaStreamingLinks < Base
      include AlgoliaUtils

      STREAMING_URL_PATH = "/media/streamingUrls/%clip_id%"

      def initialize
        super()
        self.class.base_uri site_base_uri
        self.class.headers "X-Requested-With" => "XMLHttpRequest"
        self.class.follow_redirects false
        self.class.headers "Cookie" => XXXDownload.config.cookie
      end

      # @param [Data::Scene] scene_data
      # @return [Data::StreamingLinks, NilClass]
      # noinspection RubyMismatchedReturnType
      def fetch(scene_data, count = 0)
        path = STREAMING_URL_PATH.gsub("%clip_id%", scene_data.clip_id.to_s)

        resp = handle_response!(handle_errors: false) { self.class.get(path) }
        if resp.code == 200
          extract_streaming_links(resp.parsed_response)
        else
          handle_api_error(resp)
        end
      rescue RedirectedError => e
        # Raise a Fatal Error if we are not able to get the links after 3 tries
        raise e if count > 3

        # TODO: Look for a way to check cookies before making a request
        # First time requests will always raise this
        cookie = authenticator.request_cookie(force_request: true)
        self.class.headers "Cookie" => cookie
        fetch(scene_data, count + 1)
      end

      def authenticator
        @authenticator ||= SiteAuthenticator.new(site_base_uri)
      end

      private

      def extract_streaming_links(resp) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        return nil if resp == []

        case resp
        when Array
          if %w[format url].all? { |k| resp.first&.keys&.include?(k) }
            formatted = resp.each_with_object({}) { |r, hash| hash["res_#{r["format"]}"] = r["url"] }
            Data::StreamingLinks.new(formatted)
          end
        when Hash
          formatted = resp.transform_keys! { |k| "res_#{k}" }
          Data::StreamingLinks.new(formatted)
        else
          XXXDownload.logger.error "Unexpected response format: #{resp.class}"
          XXXDownload.logger.ap resp, :error
        end
      end
    end
  end
end
