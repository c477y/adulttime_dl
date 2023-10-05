# frozen_string_literal: true

require "adulttime_dl/data/cum_louder_scene"

module AdultTimeDL
  module Net
    class CumLouderIndex < BaseIndex
      def search_by_actor(url)
        all_scenes = fetch_all_scenes(url) do |doc|
          doc.css(".medida .muestra-escena")
             .map { |x| x["href"] }
             .compact
             .map { |x| x.gsub("https://www.cumlouder.com", "") }
             .select { |x| x.start_with?("/porn-video") }
             .map { |x| "https://www.cumlouder.com#{x}" }
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

      def process_scenes(scene_urls)
        scene_urls.map do |url|
          Data::Scene.new(placeholder_scene_hash.merge(video_link: url, refresher: Data::CumLouderScene))
        end
      end

      def fetch?(url, page = 1)
        fetch!(url, page)
      rescue AdultTimeDL::NotFoundError
        nil
      end

      # @param [String] url
      # @param [Integer] page
      def fetch!(url, page = 1)
        url = paginate_url(url, page)
        http_resp = HTTParty.get(url, headers: default_headers)
        resp = handle_response!(http_resp, return_raw: true)
        Nokogiri::HTML(resp.body)
      end

      def paginate_url(url, page)
        url.chop! if url.end_with?("/")
        "#{url}/#{page}"
      end
    end
  end
end
