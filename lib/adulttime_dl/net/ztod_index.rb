# frozen_string_literal: true

module AdultTimeDL
  module Net
    class ZTODIndex < AlgoliaClient
      SCENES_INDEX_NAME = "all_scenes"
      MOVIE_INDEX_NAME = "all_movies"
      ACTOR_INDEX_NAME = "all_actors"

      def search_by_actor(actor_id, actor_name, retry_count: 0)
        if retry_count > 5
          raise FatalError, "[RETRY EXCEEDED] #{self.class.name} ran search_by_actor more than #{retry_count} times"
        end

        query = default_options.merge(filters: "actors.name:'#{actor_name}'")
        resp = scenes_index.search("", query)
        AdultTimeDL.logger.error("[EMPTY RESULT] #{actor_name}") if resp[:hits].empty?
        make_struct(resp[:hits])
      rescue Algolia::AlgoliaHttpError => e
        AdultTimeDL.logger.error "[ALGOLIA ERROR] #{e.message}"
        refresh_algolia
        search_by_actor(actor_id, actor_name, retry_count: retry_count + 1)
      end

      def search_by_movie(movie_id, movie_name, retry_count: 0)
        if retry_count > 5
          raise FatalError, "[RETRY EXCEEDED] #{self.class.name} ran search_by_movie more than #{retry_count} times"
        end

        resp = scenes_index.search("", { filters: "movie_id:#{movie_id}" })
        AdultTimeDL.logger.error("[EMPTY RESULT] #{movie_name}") if resp[:hits].empty?
        make_struct(resp[:hits])
      rescue Algolia::AlgoliaHttpError => e
        AdultTimeDL.logger.error "[ALGOLIA ERROR] #{e.message}"
        refresh_algolia
        search_by_movie(movie_id, movie_name, retry_count: retry_count + 1)
      end

      private

      def refresh_algolia
        AdultTimeDL.logger.info "[REFRESH ALGOLIA TOKEN]"
        @movie_index = client(true).init_index(MOVIE_INDEX_NAME)
        @actor_index = client.init_index(ACTOR_INDEX_NAME)
        @scenes_index = client.init_index(SCENES_INDEX_NAME)
      end

      def default_facet_filters
        %w[upcoming:0]
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
