# frozen_string_literal: true

module AdultTimeDL
  module Net
    class StreamingLinks < Base
      include HTTParty

      base_uri "https://members.adulttime.com"
      logger AdultTimeDL.logger, :debug

      STREAMING_URL_PATH = "/media/streamingUrls/%clip_id%"

      attr_reader :cookie

      def initialize(cookie)
        super()
        @cookie = cookie
      end

      def fetch(clip_id)
        path = STREAMING_URL_PATH.gsub("%clip_id%", clip_id.to_s)
        resp = handle_response!(self.class.get(path, headers: headers))
        resp.transform_keys! { |k| "res_#{k}" }
        Data::StreamingLinks.new(resp)
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
