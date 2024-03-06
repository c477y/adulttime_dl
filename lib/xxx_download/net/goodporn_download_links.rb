# frozen_string_literal: true

module XXXDownload
  module Net
    class GoodpornDownloadLinks < Base
      def fetch(scene_data)
        scene_data.downloading_links.send(config.quality)
      end
    end
  end
end
