# frozen_string_literal: true

module AdultTimeDL
  module Net
    class HouseOFyreDownloadLinks < Base
      # @param [Data::Config] config
      def initialize(config)
        @config = config
        super()
      end

      def fetch(scene_data)
        scene_data.downloading_links.send(@config.quality)
      end
    end
  end
end

