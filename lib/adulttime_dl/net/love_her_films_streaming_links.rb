# frozen_string_literal: true

module AdultTimeDL
  module Net
    class LoveHerFilmsStreamingLinks < Base
      include BrowserSupport

      BASE_URL = "https://www.loveherfilms.com"

      attr_reader :m3u8_links

      def initialize(config)
        self.class.cookie(BASE_URL, config.cookie)
        @config = config
        super()
      end

      def fetch(scene_data)
        self.class.request(headless: !@config.verbose) do |driver, wait|
          @m3u8_links = []
          driver.intercept do |request, &continue|
            uri = URI.parse(request.url)
            m3u8_links << request.url if uri.path.end_with?(".m3u8")
            continue.call(request)
          rescue Selenium::WebDriver::Error::WebDriverError => e
            AdultTimeDL.logger.error "[INTERCEPTOR ERROR] #{e}"
          end
          AdultTimeDL.logger.debug "PROCESSING URL #{scene_data.video_link}"
          driver.get(scene_data.video_link)
          wait.until { m3u8_links.length.positive? }
        end
        AdultTimeDL.logger.debug "M3U8 URLS captured:"
        m3u8_links.each do |url|
          AdultTimeDL.logger.debug "\t#{url}"
        end
        Data::StreamingLinks.new(default: m3u8_links)
      end
    end
  end
end
