# frozen_string_literal: true

module XXXDownload
  module Net
    module Generators
      class AlgoliaGenerator < BaseGenerator
        include AlgoliaLinkParser
        include AlgoliaUtils

        TAG = "ALGOLIA_GENERATOR"

        def actors
          @accumulator = []
          actors_paginated
        end

        def movies
          @accumulator = []
          movies_paginated
        end

        private

        def actors_paginated(page = 0)
          with_retry do
            XXXDownload.logger.info("[#{TAG}] Fetching page #{page}")

            # https://www.zerotolerancefilms.com/en/pornstar/view/Jasmine-Tame/113411
            opts = default_scene_options.merge(page:,
                                               facetFilters: ["male:0"],
                                               attributesToRetrieve: %w[name actor_id url_name])
            resp = actor_index.search("", opts)

            if resp[:hits].empty?
              XXXDownload.logger.debug("[#{TAG}] REACHED END OF RESULTS")
              return accumulator
            end

            urls = resp[:hits].map do |x|
              File.join("https://www.zerotolerancefilms.com/en/pornstar/view",
                        x[:url_name],
                        x[:actor_id].to_s)
            end

            XXXDownload.logger.debug "[#{TAG}] Adding #{urls.size} urls to accumulator"
            accumulator.concat(urls)

            XXXDownload.logger.debug "[#{TAG}] Current accumulator size: #{accumulator.size}"

            actors_paginated(page + 1)
          end

          accumulator
        end

        def movies_paginated(page = 0)
          with_retry do
            XXXDownload.logger.info("[#{TAG}] Fetching page #{page}")

            opts = default_scene_options.merge(page:,
                                               attributesToRetrieve: %w[movie_id title url_title])
            resp = movie_index.search("", opts)

            if resp[:hits].empty?
              XXXDownload.logger.debug("[#{TAG}] REACHED END OF RESULTS")
              return accumulator
            end

            urls = resp[:hits].map do |x|
              File.join("https://www.zerotolerancefilms.com/en/movie/",
                        x[:url_title],
                        x[:movie_id].to_s)
            end

            XXXDownload.logger.debug "[#{TAG}] Adding #{urls.size} urls to accumulator"
            accumulator.concat(urls)

            XXXDownload.logger.debug "[#{TAG}] Current accumulator size: #{accumulator.size}"

            movies_paginated(page + 1)
          end
        end

        def accumulator
          @accumulator ||= []
        end

        def with_retry(current_attempt: 1, max_attempts: 5, &block)
          if current_attempt > max_attempts
            raise FatalError, "[#{TAG} RETRY EXCEEDED] exceeded retry attempts #{max_attempts}"
          end

          block.call
        rescue Algolia::AlgoliaHttpError => e
          XXXDownload.logger.error "[#{TAG} AlgoliaHttpError] #{e.message}"
          refresh_algolia
          with_retry(current_attempt: current_attempt + 1, max_attempts:, &block)
        end

        def default_scene_options
          {
            # attributesToRetrieve: attributes,
            hitsPerPage: 1000,
            attributesToHighlight: []
          }
        end

        def refresh_algolia
          XXXDownload.logger.info "[#{TAG}] Refresh Algolia token"
          @movie_index = client(true).init_index(MOVIE_INDEX_NAME)
          @actor_index = client.init_index(ACTOR_INDEX_NAME)
        end

        def movie_index
          @movie_index ||= client.init_index(MOVIE_INDEX_NAME)
        end

        def actor_index
          @actor_index ||= client.init_index(ACTOR_INDEX_NAME)
        end

        def client(force_refresh = false)
          if force_refresh || !defined?(@algolia_config) || !defined?(@client)
            @algolia_config = begin
              # This will call the website to get the credentials.
              app_id, api_key = algolia_credentials
              c = Algolia::Search::Config.new(application_id: app_id, api_key:)
              c.set_extra_header("Referer", non_member_base_url)
              c
            end
            @client = Algolia::Search::Client.new(@algolia_config, logger: XXXDownload.logger)
            return @client
          end

          @client ||= Algolia::Search::Client.new(@algolia_config, logger: XXXDownload.logger)
        end

        # @return [[String, String]]
        def algolia_credentials
          credentials = case config.site
                        when "ztod"
                          AlgoliaCredentials.new(Constants::ZTOD_BASE_URL)
                        else
                          raise FatalError, "received unexpected site name #{config.site}"
                        end
          [credentials.algolia_application_id, credentials.algolia_api_key]
        end
      end
    end
  end
end
