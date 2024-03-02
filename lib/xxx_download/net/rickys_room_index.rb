# frozen_string_literal: true

module XXXDownload
  module Net
    class RickysRoomIndex < YppClient
      LOGIN_URL = "https://members.rickysroom.com"
      TOUR_BASE_URL = "https://www.rickysroom.com"
      NETWORK = "Ricky's Room"
      COLLECTION_TAG = "rir"

      def initialize
        super(Refreshers::YppRefresh, LOGIN_URL, TOUR_BASE_URL, NETWORK, COLLECTION_TAG)
        self.class.base_uri LOGIN_URL
      end

      def search_by_page(url)
        ensure_cookies!

        resp = handle_response!(return_raw: true) { self.class.get(url) }
        doc = Nokogiri::HTML(resp.body)
        links = doc.css("#video-wrapper .video-model-section .video-info a")
                   .map { |x| x["href"] }
                   .select { |x| x.include?("/videos/") || x.include?("/bts/") }
                   .map { |x| x.gsub(login_url, "").gsub(tour_base_url, "") }
                   .uniq
        XXXDownload.logger.extra "[#{TAG}] Found #{links.size} scenes"

        links.map do |href|
          sd = Data::Scene.new(
            video_link: href,
            refresher: @refresher_klass.new(href, @cookies, login_url, tour_base_url, network, collection_tag,
                                            default_actor),
            **Data::Scene::LAZY
          )
          XXXDownload.logger.debug "[#{TAG}] Processing scene: #{href}"
          XXXDownload.logger.ap sd.to_h, :extra
          sd
        end
      end

      private

      # @param [String] url
      # @return [String]
      def actors_site_name(url)
        resp = handle_response!(return_raw: true) { self.class.get(url) }
        doc = Nokogiri::HTML(resp.body)
        name = doc.css(".model-info .details h1").text.strip
        raise FatalError, "Unable to fetch actor name from URL: #{url}" if name.nil?

        name
      end
    end
  end
end
