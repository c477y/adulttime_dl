# frozen_string_literal: true

module XXXDownload
  module Net
    # @deprecated This Index is no longer supported
    class PornveStreamingLinks < Base
      include BrowserSupport

      def fetch(scene_data)
        links = capture_links(scene_data.video_link,
                              play_button: { id: "fplayer_fluid_state_button" },
                              headless: !@config.verbose)
        Data::StreamingLinks.new(default: links)
      end
    end
  end
end
