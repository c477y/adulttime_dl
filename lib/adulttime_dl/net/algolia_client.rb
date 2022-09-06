# frozen_string_literal: true

module AdultTimeDL
  module Net
    class AlgoliaClient < BaseIndex
      include AlgoliaLinkParser

      # @return [Algolia::Search::Client]
      def client(refresh = false)
        if refresh
          @client = Algolia::Search::Client.new(config(true), logger: AdultTimeDL.logger)
        else
          @client ||= Algolia::Search::Client.new(config, logger: AdultTimeDL.logger)
        end
      end

      def search_by_actor(url)
        actor_name = self.class.entity_name(url)
        with_retry(actor_name) do |m_actor_name|
          query = default_scene_options.merge(filters: "actors.name:'#{m_actor_name}'")
          resp = scenes_index.search("", query)
          AdultTimeDL.logger.error("[EMPTY RESULT] #{m_actor_name}") if resp[:hits].empty?
          make_struct(resp[:hits])
        end
      end

      def search_by_movie(url)
        movie_id = self.class.entity_id(url)
        movie_name = self.class.entity_name(url)
        with_retry(movie_id, movie_name) do |m_movie_id, m_movie_name|
          query = default_scene_options.merge(filters: "movie_id:#{m_movie_id}")
          resp = scenes_index.search("", query)
          AdultTimeDL.logger.error("[EMPTY RESULT] #{m_movie_name}") if resp[:hits].empty?
          make_struct(resp[:hits])
        end
      end

      private

      def with_retry(*parameters, current_attempt: 1, max_attempts: 5, &block)
        if current_attempt > max_attempts
          raise FatalError, "[RETRY EXCEEDED] #{self.class.name} ran exceeded retry attempts #{max_attempts}"
        end

        block.call(*parameters)
      rescue Algolia::AlgoliaHttpError => e
        AdultTimeDL.logger.error "[ALGOLIA ERROR] #{e.message}"
        refresh_algolia
        with_retry(*parameters, current_attempt: current_attempt + 1, max_attempts: max_attempts, &block)
      end

      def movie_index
        raise FatalError, "#{self.class.name} does not implement movie_index"
      end

      def actor_index
        raise FatalError, "#{self.class.name} does not implement actor_index"
      end

      def scenes_index
        raise FatalError, "#{self.class.name} does not implement scenes_index"
      end

      def refresh_algolia
        raise FatalError, "#{self.class.name} does not implement refresh_algolia"
      end

      def actor_attr_opts
        {
          attributesToRetrieve: %w[actor_id name gender url_name],
          hitsPerPage: 1
        }
      end

      def make_struct(hits)
        hits.map do |hit|
          Data::Scene.new(hit)
        rescue Dry::Struct::Error => e
          AdultTimeDL.logger.error "Unable to parse record due to #{e.message}"
          AdultTimeDL.logger.debug hit
          nil
        end.compact
      end

      def default_scene_options
        {
          # attributesToRetrieve: attributes,
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
      def config(refresh = false)
        if refresh
          @config = begin
            app_id, api_key = algolia_credentials
            c = Algolia::Search::Config.new(application_id: app_id, api_key: api_key)
            c.set_extra_header("Referer", referrer(config.site))
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
        when "blowpass" then "#{Constants::BLOW_PASS_BASE_URL}/"
        else raise FatalError, "received unexpected site name #{site}"
        end
      end

      # @return [[String, String]]
      def algolia_credentials
        credentials = case config.site
                      when "blowpass"
                        fetch_from_config? ||
                        Net::AlgoliaCredentialsBrowser.new(config, Constants::BLOW_PASS_BASE_URL)
                      else Net::AlgoliaCredentials.new(config.site)
                      end
        [credentials.algolia_application_id, credentials.algolia_api_key]
      end

      AlgoliaCredentials = Struct.new(:algolia_application_id, :algolia_api_key)

      def fetch_from_config?
        site_config = config.current_site_config
        return nil if !config.site || site_config[:algolia_application_id].nil? || site_config[:algolia_api_key].nil?

        AlgoliaCredentials.new(site_config[:algolia_application_id], site_config[:algolia_api_key])
      end
    end
  end
end
