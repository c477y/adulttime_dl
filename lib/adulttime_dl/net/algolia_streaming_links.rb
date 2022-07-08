# frozen_string_literal: true

module AdultTimeDL
  module Net
    class AlgoliaStreamingLinks < Base
      include HTTParty

      STREAMING_URL_PATH = "/media/streamingUrls/%clip_id%"

      attr_reader :cookie

      # @param [Data::Config] config
      def initialize(config, base_url)
        super()
        self.class.base_uri(base_url)
        self.class.logger AdultTimeDL.logger, :debug
        @cookie = config.cookie
      end

      # @param [String] clip_id
      # @return [Data::StreamingLinks, NilClass]
      def fetch(clip_id)
        path = STREAMING_URL_PATH.gsub("%clip_id%", clip_id.to_s)
        resp = handle_response!(self.class.get(path, headers: headers))
        return nil if resp == []

        resp.transform_keys! { |k| "res_#{k}" }
        Data::StreamingLinks.new(resp)
      rescue NoMethodError => e
        AdultTimeDL.logger.error "[LINK FETCH ERROR] #{e.message}"
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
