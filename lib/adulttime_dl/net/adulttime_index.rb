# frozen_string_literal: true

module AdultTimeDL
  module Net
    class AdultTimeIndex < AlgoliaClient
      INDEX_NAME = "all_scenes_latest_desc"

      def search_by_actor(_actor_id, actor_name)
        facet_filters = { facetFilters: default_facet_filters << "actors.name:#{actor_name}" }
        query = default_options.merge(facet_filters)
        resp = index.search("", query)
        AdultTimeDL.logger.error("[EMPTY RESULT] #{actor_name}") if resp[:hits].empty?
        make_struct(resp[:hits])
      end

      private

      def index
        @index ||= client.init_index(INDEX_NAME)
      end
    end
  end
end
