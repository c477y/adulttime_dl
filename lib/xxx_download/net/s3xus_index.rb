# frozen_string_literal: true

module XXXDownload
  module Net
    class S3xusIndex < YppClient
      LOGIN_URL = "https://members.s3xus.com"
      TOUR_BASE_URL = "https://www.s3xus.com"
      NETWORK = "S3xus"
      COLLECTION_TAG = "S3x"
      DEFAULT_ACTOR = "Brad Newman"

      def initialize
        super(Refreshers::YppRefresh, LOGIN_URL, TOUR_BASE_URL, NETWORK, COLLECTION_TAG, DEFAULT_ACTOR)
        self.class.base_uri LOGIN_URL
      end

      # search_by_page relies on HTTP web scraping, which can be different for each site
      # this has to be implemented manually for all sites
      def search_by_page(url)
        ensure_cookies!

        resp = handle_response!(return_raw: true) { self.class.get(url) }
        doc = Nokogiri::HTML(resp.body)
        doc.css(".featured-scenes .card .link-overlay").map do |x|
          href = x["href"]
          # remove any base URL occurrences from the href
          href.gsub(login_url, "").gsub(tour_base_url, "")
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
      # @return [String, NilClass]
      def actors_site_name(url)
        resp = handle_response!(return_raw: true) { self.class.get(url) }
        doc = Nokogiri::HTML(resp.body)
        name = doc.css(".model-container .model-name h1").text.strip
        raise FatalError, "Unable to fetch actor name from URL: #{url}" if name.nil?

        name
      end
    end
  end
end
