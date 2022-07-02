# frozen_string_literal: true

module AdultTimeDL
  module Net
    class ScenesIndex < Base
      INDEX_NAME = "all_scenes_latest_desc"

      def search_by_actor_name(actor_name)
        facet_filters = { facetFilters: default_facet_filters << "actors.name:#{actor_name}" }
        query = default_options.merge(facet_filters)
        resp = index.search("", query)
        make_struct(resp[:hits])
      end

      # DO NOT USE
      def search_by_actor_id(actor_id)
        facet_filters = { facetFilters: default_facet_filters << "actors.actor_id:#{actor_id}" }
        query = default_options.merge(facet_filters)
        resp = index.search("", query)
        make_struct(resp[:hits])
      end

      private

      def make_struct(hits)
        hits.map do |hit|
          Data::AlgoliaScene.new(hit)
        rescue Dry::Struct::Error => e
          AdultTimeDL.logger.error "Unable to parse record due to #{e.message}"
          AdultTimeDL.logger.debug hit
          nil
        end.compact
      end

      def default_options
        {
          attributesToRetrieve: attributes,
          hitsPerPage: 1000
        }
      end

      def attributes
        %w[clip_id title actors release_date network_name]
      end

      def default_facet_filters
        %w[upcoming:0 content_tags:straight]
      end

      def client
        @client ||= Algolia::Search::Client.new(config, logger: AdultTimeDL.logger)
      end

      def index
        @index ||= client.init_index(INDEX_NAME)
      end

      def config
        @config ||= begin
          app_id, api_key = algolia_credentials
          c = Algolia::Search::Config.new(application_id: app_id, api_key: api_key)
          c.set_extra_header("Referer", "https://members.adulttime.com/")
          c
        end
      end

      def algolia_credentials
        credentials = Net::AlgoliaCredentials.new
        [credentials.algolia_application_id, credentials.algolia_api_key]
      end
    end
  end
end
