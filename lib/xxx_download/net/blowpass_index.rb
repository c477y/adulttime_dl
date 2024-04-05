# frozen_string_literal: true

module XXXDownload
  module Net
    class BlowpassIndex < AlgoliaClient
      SCENES_INDEX_NAME = "all_scenes"
      ACTOR_INDEX_NAME = "all_actors"

      private

      def refresh_algolia
        XXXDownload.logger.info "[REFRESH ALGOLIA TOKEN]"
        client(true)
        @actor_index = client.init_index(ACTOR_INDEX_NAME)
        @scenes_index = client.init_index(SCENES_INDEX_NAME)
      end

      def scenes_index
        @scenes_index ||= client.init_index(SCENES_INDEX_NAME)
      end

      def actor_index
        @actor_index ||= client.init_index(ACTOR_INDEX_NAME)
      end
    end
  end
end
