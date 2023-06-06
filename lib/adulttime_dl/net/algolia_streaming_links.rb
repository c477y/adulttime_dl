# frozen_string_literal: true

module AdultTimeDL
  module Net
    class AlgoliaStreamingLinks < Base
      include HTTParty

      STREAMING_URL_PATH = "/media/streamingUrls/%clip_id%"

      attr_reader :cookie

      follow_redirects false

      # @param [Data::Config] config
      def initialize(config, base_url)
        super()
        self.class.base_uri(base_url)
        self.class.logger AdultTimeDL.logger, :debug
        @cookie = config.cookie
      end

      # @param [Data::Scene] scene_data
      # @return [Data::StreamingLinks, NilClass]
      def fetch(scene_data)
        path = STREAMING_URL_PATH.gsub("%clip_id%", scene_data.clip_id.to_s)
        resp = handle_response!(self.class.get(path, headers: headers))
        return nil if resp == []

        if resp.is_a?(Array) && resp.first&.keys&.sort == %w[format url]
          transformed_resp = {}
          resp.each do |r|
            key = "res_#{r["format"]}"
            transformed_resp[key] = r["url"]
          end
          Data::StreamingLinks.new(transformed_resp)
        elsif resp.is_a?(Hash)
          resp.transform_keys! { |k| "res_#{k}" }
          Data::StreamingLinks.new(resp)
        end
      rescue NoMethodError => e
        AdultTimeDL.logger.warn "[LINK FETCH ERROR] #{e.message}"
        AdultTimeDL.logger.warn "PLEASE OPEN AN ISSUE ON GITHUB WITH THE ABOVE ERROR MESSAGE"
        nil
      end

      private

      def headers
        default_headers.merge(
          {
            "X-Requested-With" => "XMLHttpRequest",
            "Cookie" => cookie
          }
        )
      end
    end
  end
end
