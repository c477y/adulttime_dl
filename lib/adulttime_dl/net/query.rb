# frozen_string_literal: true

module AdultTimeDL
  module Net
    class Query < Base
      attr_reader :actor_name

      include HTTParty

      base_uri "https://tsmkfa364q-dsn.algolia.net"
      logger AdultTimeDL.logger, :debug

      INDEX_ENDPOINT = "/1/indexes/*/queries"
      INDEX_NAME = "all_scenes_latest_desc"

      def scenes(actor_name)
        @actor_name = actor_name

        options = {
          headers: default_headers.merge(**adult_time_algolia_headers),
          query: algolia_params,
          body: request.to_json
        }
        resp = handle_response!(self.class.post(INDEX_ENDPOINT, options))
        make_struct(resp["results"][0]["hits"])
      end

      def make_struct(hits)
        hits.map do |hit|
          Data::AlgoliaScene.new(hit)
        rescue Dry::Struct::Error => e
          AdultTimeDL.logger.error "Unable to parse record due to #{e.message}"
          AdultTimeDL.logger.debug hit
          nil
        end.compact
      end

      def algolia_params
        Net::AlgoliaCredentials.new.algolia_params
      end

      def adult_time_algolia_headers
        { "Content-Type": "application/x-www-form-urlencoded", "Referer": "https://members.adulttime.com/" }
      end

      def request
        {
          requests: [
            indexName: INDEX_NAME,
            params: params
          ]
        }
      end

      def params
        URI.encode_www_form(
          {
            query: "",
            hitsPerPage: 1000,
            page: 0,
            attributesToRetrieve: attributes,
            clickAnalytics: true,
            facets: [].to_json,
            tagFilters: "",
            facetFilters: facet_filters
          }
        )
      end

      # This doesn't seem to work for some reason.
      def attributes
        %w[clip_id title actors release_date network_name].to_json
      end

      def actors_facet_filters
        ["actors.name:#{actor_name}"]
      end

      def facet_filters
        [released_scenes_facet_filter, actors_facet_filters, content_tags_facet_filters].to_json
      end

      def content_tags_facet_filters
        # Add this to download lesbian scenes
        # content_tags:lesbian
        %w[content_tags:straight]
      end

      def released_scenes_facet_filter
        "upcoming:0"
      end
    end
  end
end
