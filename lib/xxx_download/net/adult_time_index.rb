# frozen_string_literal: true

module XXXDownload
  module Net
    class AdultTimeIndex < AlgoliaClient
      ACTOR_INDEX_NAME = "all_actors"
      SCENES_INDEX_NAME = "all_scenes_latest_desc"
      MOVIE_INDEX_NAME = "all_movies_latest_desc"
      COLLECTION_TAG = "AT"

      private

      def refresh_algolia
        XXXDownload.logger.info "[REFRESH ALGOLIA TOKEN]"
        @movie_index = client(true).init_index(MOVIE_INDEX_NAME)
        @actor_index = client.init_index(ACTOR_INDEX_NAME)
        @scenes_index = client.init_index(SCENES_INDEX_NAME)
      end

      def movie_index
        @movie_index ||= client.init_index(MOVIE_INDEX_NAME)
      end

      def actor_index
        @actor_index ||= client.init_index(ACTOR_INDEX_NAME)
      end

      def scenes_index
        @scenes_index ||= client.init_index(SCENES_INDEX_NAME)
      end
    end
  end
end
