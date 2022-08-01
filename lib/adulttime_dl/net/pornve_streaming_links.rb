# frozen_string_literal: true

module AdultTimeDL
  module Net
    class PornVEStreamingLinks < Base
      include BrowserSupport

      def initialize(config)
        @config = config
        super()
      end

      def fetch(scene_data)
        links = capture_links(scene_data.video_link,
                              play_button: { id: "fplayer_fluid_state_button" },
                              headless: !@config.verbose)
        Data::StreamingLinks.new(default: links)
      end
    end
  end
end
