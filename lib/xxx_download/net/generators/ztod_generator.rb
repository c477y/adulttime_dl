# frozen_string_literal: true

module XXXDownload
  module Net
    module Generators
      class ZtodGenerator < AlgoliaGenerator
        MOVIE_INDEX_NAME = "all_movies_latest_desc"
        ACTOR_INDEX_NAME = "all_actors_name_asc"

        private

        def refresh_algolia
          XXXDownload.logger.info "[REFRESH ALGOLIA TOKEN]"
          @movie_index = client(true).init_index(MOVIE_INDEX_NAME)
          @actor_index = client.init_index(ACTOR_INDEX_NAME)
        end

        def movie_index
          @movie_index ||= client.init_index(MOVIE_INDEX_NAME)
        end

        def actor_index
          @actor_index ||= client.init_index(ACTOR_INDEX_NAME)
        end
      end
    end
  end
end
