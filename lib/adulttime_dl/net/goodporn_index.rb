# frozen_string_literal: true

require "adulttime_dl/data/good_porn_scene"

module AdultTimeDL
  module Net
    class GoodPornIndex < BaseIndex
      def search_by_actor(url)
        all_scenes = fetch_all_scenes(url) do |doc|
          doc.css(".list-videos .item .thumb-link").map { |x| x["href"] }.compact
        end
        process_scenes(all_scenes)
      end

      private

      def fetch_all_scenes(url, &block)
        scene_links = []
        page = 1
        loop do
          AdultTimeDL.logger.info "[FETCH PAGE] #{page}"
          doc = fetch?(url, page)
          if doc.nil?
            AdultTimeDL.logger.debug "[REACHED END OF PAGES]"
            break
          end

          scene_links.concat(block.call(doc))
          page += 1
        end
        scene_links
      end

      # @param [Array[String]] scene_urls
      # @return [Array[Data::Scene]]
      def process_scenes(scene_urls)
        scene_urls.map do |url|
          Data::Scene.new(placeholder_scene_hash.merge(video_link: url, refresher: Data::GoodPornScene))
        end
      end

      def fetch?(url, page = 1)
        fetch!(url, page)
      rescue AdultTimeDL::NotFoundError
        nil
      end

      def fetch!(url, page = 1)
        http_resp = HTTParty.get(url, query: { from: page }, headers: default_headers)
        resp = handle_response!(http_resp, return_raw: true)
        Nokogiri::HTML(resp.body)
      end
    end
  end
end
