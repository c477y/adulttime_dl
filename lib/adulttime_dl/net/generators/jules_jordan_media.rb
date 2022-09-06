# frozen_string_literal: true

module AdultTimeDL
  module Net
    module Generators
      class JulesJordanMedia < BaseGenerator
        include HTTParty

        def initialize(config, base_uri)
          super(config)
          configure_http(base_uri)
        end

        def configure_http(base_uri)
          self.class.base_uri(base_uri)
          self.class.logger AdultTimeDL.logger, :debug
          self.class.follow_redirects false
          self.class.headers headers
        end

        ACTOR_PAGE = "/members/models/models_%page%_n.html"
        MOVIES_PAGE = "/members/dvds/dvds_page_%page%.html"

        def actors(_female_only = nil)
          recursive_actors_fetch
        end

        def movies
          recursive_movies_fetch
        end

        def recursive_actors_fetch(aggregated_response: [], current_page: 1)
          AdultTimeDL.logger.info "Fetching page #{current_page}"
          doc = fetch(ACTOR_PAGE.gsub("%page%", current_page.to_s))
          actor_component = doc.css(".category_listing_block .category_listing_wrapper_models .update_details a")
          return aggregated_response.uniq! if actor_component.length.zero?

          actors = actor_component.map { |link| link["href"] }

          aggregated_response.concat(actors)
          AdultTimeDL.logger.debug "Aggregating #{actors.length} actor links. " \
                                            "Extracted #{aggregated_response.length} so far."
          recursive_actors_fetch(aggregated_response: aggregated_response, current_page: current_page + 1)
        end

        def recursive_movies_fetch(aggregated_response: [], current_page: 1)
          AdultTimeDL.logger.info "Fetching page #{current_page}"
          doc = fetch(MOVIES_PAGE.gsub("%page%", current_page.to_s))
          movie_component = doc.css(".dvd_block .dvd_wrapper .update_details a")
          return aggregated_response.uniq! if movie_component.length.zero?

          movies = movie_component.map { |link| link["href"] }

          aggregated_response.concat(movies)
          AdultTimeDL.logger.debug "Aggregating #{movies.length} actor links. " \
                                            "Extracted #{aggregated_response.length} so far."
          recursive_movies_fetch(aggregated_response: aggregated_response, current_page: current_page + 1)
        end

        def fetch(url)
          http_resp = self.class.get(url)
          resp = handle_response!(http_resp, return_raw: true)
          doc = Nokogiri::HTML(resp.body)
          return doc unless doc.title.end_with?("Members Login")

          raise RedirectedError, endpoint: url, code: http_resp.code,
                                 body: http_resp.parsed_response, headers: http_resp.headers
        end

        def headers
          default_headers.merge(
            "Accept" => "*/*",
            "Connection" => "keep-alive",
            "DNT" => "1",
            "Cookie" => config.cookie
          )
        end
      end
    end
  end
end
