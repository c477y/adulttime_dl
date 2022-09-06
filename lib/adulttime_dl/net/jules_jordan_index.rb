# frozen_string_literal: true

module AdultTimeDL
  module Net
    class JulesJordanIndex < BaseIndex
      def search_by_actor(url)
        doc = fetch(url)
        doc.css(".category_listing_block .category_listing_wrapper_updates")
           .map { |x| JulesJordanActorSearch.new.make_scene_data(x) }
      end

      def search_by_movie(url)
        doc = fetch(url)
        doc.css(".content_wrapper .dvd_details")
           .map { |x| JulesJordanMovieSearch.new.make_scene_data(x) }
      end

      def search_by_all_scenes(url)
        correct_url = url.gsub("/trial", "/members")
        doc = fetch(correct_url)
        [JulesJordanSceneSearch.new.make_scene_data(url, doc)]
      end

      private

      class JulesJordanSceneSearch
        def make_scene_data(url, doc)
          Data::UnknownActorGenderScene.new(
            title: title(doc),
            actors: actors(doc),
            release_date: nil,
            network_name: "JulesJordan",
            download_sizes: [], # exclusive to algolia scenes
            is_streamable: false,
            video_link: url
          )
        end

        private

        def title(doc)
          doc.css(".title_bar_hilite").text.strip
        end

        def actors(doc)
          # doc.css(".content_img div .update_models a")
          doc.css(".backgroundcolor_info .update_models a")
             .map(&:text)
             .map(&:strip)
             .map { |x| Data::Actor.new(name: x, gender: "unknown") }
        end
      end

      class JulesJordanActorSearch
        def make_scene_data(doc)
          Data::UnknownActorGenderScene.new(
            title: title(doc),
            actors: actors(doc),
            release_date: nil,
            network_name: "JulesJordan",
            download_sizes: [], # exclusive to algolia scenes
            is_streamable: false,
            video_link: video_link(doc)
          )
        end

        private

        def video_link(doc)
          (doc.css(".update_details a") || doc.css(".content_img a"))
            .map { |link| link["href"] }.compact.first
        end

        def title(doc)
          doc.css(".content_img div").children&.first&.text&.strip ||
            doc.css(".update_details a")[1]&.text&.strip
        end

        def actors(doc)
          # doc.css(".content_img div .update_models a")
          doc.css(".update_models a")
             .map(&:text)
             .map(&:strip)
             .map { |x| Data::Actor.new(name: x, gender: "unknown") }
        end
      end

      class JulesJordanMovieSearch
        def make_scene_data(doc)
          Data::UnknownActorGenderScene.new(
            title: title(doc),
            actors: actors(doc),
            release_date: nil,
            network_name: "JulesJordan",
            download_sizes: [], # exclusive to algolia scenes
            is_streamable: false,
            video_link: video_link(doc)
          )
        end

        private

        def video_link(doc)
          doc.css(".cell a").map { |link| link["href"] }.compact.first
        end

        def title(doc)
          doc.css(".cell a").children.first.text.strip
        end

        def actors(doc)
          doc.css(".cell .update_models a")
             .map(&:text)
             .map(&:strip)
             .map { |x| Data::Actor.new(name: x, gender: "unknown") }
        end
      end

      def fetch(actor_page)
        http_resp = HTTParty.get(actor_page, headers: headers, follow_redirects: false)
        resp = handle_response!(http_resp, return_raw: true)
        doc = Nokogiri::HTML(resp.body)
        return doc unless doc.title.end_with?("Members Login")

        raise RedirectedError.new(endpoint: actor_page, code: http_resp.code,
                                  body: http_resp.parsed_response, headers: http_resp.headers)
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
