# frozen_string_literal: true

module XXXDownload
  module Net
    module Refreshers
      class YppRefresh < BaseRefresh
        include XXXDownload::Utils

        def initialize(path, cookie, login_url, tour_base_url, network, collection_tag, default_actor)
          @path = path
          @tour_base_url = tour_base_url
          @network = network
          @collection_tag = collection_tag
          @default_actor = default_actor
          super()

          self.class.base_uri login_url
          self.class.headers "Cookie" => cookie
        end

        def refresh(**opts)
          web_resp = handle_response!(return_raw: true) { self.class.get(path) }
          doc = Nokogiri::HTML(web_resp.body)
          resp = JSON.parse(doc.css("#__NEXT_DATA__").text).dig("props", "pageProps", "content")
          if resp.nil?
            XXXDownload.logger.warn "#{TAG} Unable to find scene data in web response"
            return nil
          end
          Net::YppApiProcessor.new(tour_base_url, network, collection_tag, default_actor).make_scene_data(resp)
        rescue JSON::ParserError => e
          XXXDownload.logger.warn "#{TAG} Error parsing JSON response: #{e.message}"
          XXXDownload.logger.extra "#{TAG} response (first 100 characters): #{resp[0..100]}"
          nil
        end

        private

        TAG = "YPP_REFRESH"

        attr_reader :path, :tour_base_url, :network, :collection_tag, :default_actor
      end
    end
  end
end
