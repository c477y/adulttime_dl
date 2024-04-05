# frozen_string_literal: true

module XXXDownload
  module Net
    class EvilAngelIndex < AlgoliaClient
      SCENES_INDEX_NAME = "all_scenes"
      MOVIE_INDEX_NAME = "all_movies"
      ACTOR_INDEX_NAME = "all_actors"
      COLLECTION_TAG = "EA"

      private

      def refresh_algolia
        XXXDownload.logger.info "[REFRESH ALGOLIA TOKEN]"
        @movie_index = client(true).init_index(MOVIE_INDEX_NAME)
        @actor_index = client.init_index(ACTOR_INDEX_NAME)
        @scenes_index = client.init_index(SCENES_INDEX_NAME)
      end

      def scenes_index
        @scenes_index ||= client.init_index(SCENES_INDEX_NAME)
      end
    end
  end
end
