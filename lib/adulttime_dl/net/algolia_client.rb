# frozen_string_literal: true

module AdultTimeDL
  module Net
    class AlgoliaClient < Base
      attr_reader :client_config

      # @param [Data::Config] client_config
      def initialize(client_config)
        @client_config = client_config
        super()
      end

      # @return [Algolia::Search::Client]
      def client(refresh = false) # rubocop:disable Style/OptionalBooleanParameter
        if refresh
          @client = Algolia::Search::Client.new(config(true), logger: AdultTimeDL.logger)
        else
          @client ||= Algolia::Search::Client.new(config, logger: AdultTimeDL.logger)
        end
      end

      private

      def make_struct(hits)
        hits.map do |hit|
          Data::Scene.new(hit)
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

      def default_facet_filters
        %w[upcoming:0 content_tags:straight]
      end

      def attributes
        %w[clip_id title actors release_date network_name download_sizes movie_title]
      end

      # @return [Algolia::Search::Config]
      def config(refresh = false) # rubocop:disable Style/OptionalBooleanParameter
        if refresh
          @config = begin
            app_id, api_key = algolia_credentials
            c = Algolia::Search::Config.new(application_id: app_id, api_key: api_key)
            c.set_extra_header("Referer", referrer(client_config.site))
            c
          end

        else
          return @config if @config

          config(true)
        end
      end

      # @param [String] site
      # @return [String (frozen)]
      def referrer(site)
        case site
        when "adulttime" then "#{Constants::ADULTTIME_BASE_URL}/"
        when "ztod" then "#{Constants::ZTOD_BASE_URL}/"
        else raise FatalError, "received unexpected site name #{site}"
        end
      end

      # @return [[String, String]]
      def algolia_credentials
        credentials = Net::AlgoliaCredentials.new(client_config.site)
        [credentials.algolia_application_id, credentials.algolia_api_key]
      end
    end
  end
end
