# frozen_string_literal: true

module AdultTimeDL
  module Net
    module Generators
      class ArchAngelWorld < HTTPGenerator
        BASE_URL = "https://members.archangelworld.com"
        ACTORS_ENDPOINT = "/models/%page%/name/"
        MOVIES_ENDPOINT = "/dvds/dvds_page_%page%.html"

        def initialize(config)
          super(config, BASE_URL)
        end

        def actors(_female_only = nil)
          recursive_fetch(ACTORS_ENDPOINT)
        end

        def movies
          recursive_fetch(MOVIES_ENDPOINT)
        end

        private

        def recursive_fetch(endpoint, aggregated_response: [], current_page: 1)
          AdultTimeDL.logger.info "Fetching page #{current_page}"
          url = endpoint.gsub("%page%", current_page.to_s)
          doc = fetch(url)
          entities = doc.css(".items .item-thumb a")
                        .map { |link| link["href"] }
                        .map { |link| link.start_with?("http") ? link : File.join(BASE_URL, link) }
          return aggregated_response if entities.length.zero?

          aggregated_response.concat(entities)
          AdultTimeDL.logger.debug "Aggregating #{entities.length} links. " \
                                            "Extracted #{aggregated_response.length} so far."
          recursive_fetch(endpoint, aggregated_response: aggregated_response, current_page: current_page + 1)
        end
      end
    end
  end
end
