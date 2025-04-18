# frozen_string_literal: true

module XXXDownload
  module Net
    class LoveHerFilmsStreamingLinks < Base
      include BrowserSupport

      BASE_URL = "https://www.loveherfilms.com"

      def initialize
        cookie(BASE_URL, XXXDownload.config.cookie)
        super()
      end

      def fetch(scene_data)
        links = capture_links(scene_data.video_link)
        Data::StreamingLinks.new(default: links)
      end
    end
  end
end
