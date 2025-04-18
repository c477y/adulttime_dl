# frozen_string_literal: true

module XXXDownload
  module Net
    class AlgoliaClient < BaseIndex
      include AlgoliaLinkParser
      include AlgoliaUtils

      TAG = "ALGOLIA_CLIENT"

      # @return [Algolia::Search::Client]
      def client(force_refresh = false)
        if force_refresh || !defined?(@algolia_config) || !defined?(@client)
          @algolia_config = begin
            # This will call the website to get the credentials.
            app_id, api_key = algolia_credentials
            c = Algolia::Search::Config.new(application_id: app_id, api_key:)
            c.set_extra_header("Referer", referrer)
            c
          end
          @client = Algolia::Search::Client.new(@algolia_config, logger: XXXDownload.logger)
          return @client
        end

        @client ||= Algolia::Search::Client.new(@algolia_config, logger: XXXDownload.logger)
      end

      def search_by_actor(url)
        actor_name = self.class.entity_name(url)
        with_retry do
          query = default_scene_options.merge(filters: "actors.name:'#{actor_name}'")
          resp = scenes_index.search("", query)
          XXXDownload.logger.error("[EMPTY RESULT] #{actor_name}") if resp[:hits].empty?
          make_struct(resp[:hits])
        end
      end

      def search_by_movie(url)
        movie_id = self.class.entity_id(url)
        movie_name = self.class.entity_name(url)
        with_retry do
          query = default_scene_options.merge(filters: "movie_id:#{movie_id}")
          resp = scenes_index.search("", query)
          XXXDownload.logger.error("[EMPTY RESULT] #{movie_name}") if resp[:hits].empty?
          make_struct(resp[:hits])
        end
      end

      def actor_name(url)
        self.class.entity_name(url).titleize
      end

      private

      def with_retry(current_attempt: 1, max_attempts: 5, &block)
        if current_attempt > max_attempts
          raise FatalError, "[RETRY EXCEEDED] #{self.class.name} ran exceeded retry attempts #{max_attempts}"
        end

        block.call
      rescue Algolia::AlgoliaHttpError => e
        XXXDownload.logger.error "[ALGOLIA ERROR] #{e.message}"
        refresh_algolia
        with_retry(current_attempt: current_attempt + 1, max_attempts:, &block)
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
        XXXDownload.logger.info "#{self.class::TAG} Processing #{hits.length} scenes"
        hits.map do |hit|
          hit.tap do |h|
            h[:lazy] = false
            h[:video_link] = File.join(non_member_base_url,
                                       "en/video",
                                       h[:sitename],
                                       h[:url_title],
                                       h[:clip_id].to_s)
            h[:tags] = h[:content_tags]
            h[:collection_tag] = self.class::COLLECTION_TAG
            h[:duration] = h[:clip_length]
          end
          Data::Scene.new(hit)
        rescue Dry::Struct::Error => e
          XXXDownload.logger.error "Unable to parse record due to #{e.message}"
          XXXDownload.logger.debug hit
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

      # @return [String (frozen)]
      def referrer
        non_member_base_url
      end

      # @return [[String, String]]
      def algolia_credentials
        credentials = AlgoliaCredentials.new(non_member_base_url)
        [credentials.algolia_application_id, credentials.algolia_api_key]
      end
    end
  end
end
