# frozen_string_literal: true

module XXXDownload
  module Net
    class LoveHerFilmsIndex < BaseIndex
      def search_by_actor(url)
        doc = fetch(url)
        doc.css(".latest-scene .item-episode")
           .map { |x| make_scene_data(x) }
      end

      private

      def make_scene_data(doc)
        Data::UnknownActorGenderScene.new(
          clip_id: -1,
          title: title(doc),
          actors: actors(doc),
          release_date: release_date(doc),
          network_name: "LoveHerFilms",
          movie_title: title(doc),
          download_sizes: [],
          is_streamable: true,
          video_link: video_link(doc)
        )
      end

      def video_link(doc)
        doc.css("a").css(".item-episode-overlay").map { |link| link["href"] }.compact.first
      end

      def release_date(doc)
        date_str = doc.css(".video-date").text.strip
        time = Time.strptime(date_str, "%B %e, %Y")
        time.strftime("%Y-%m-%d") # Return time instead of date
      end

      def title(doc)
        doc.css(".item-title").text.strip
      end

      def actors(doc)
        doc.css(".information")
           .css("a")
           .map { |x| x.text.strip.gsub(",", "") }
           .map { |x| Data::Actor.new(name: x, gender: "unknown") }
      end

      def fetch(actor_page)
        resp = handle_response!(HTTParty.get(actor_page, headers:), return_raw: true)
        Nokogiri::HTML(resp.body)
      end

      def headers
        default_headers.merge(
          "Accept" => "*/*",
          "Connection" => "keep-alive",
          "DNT" => "1",
          "cookie" => config.cookie
        )
      end
    end
  end
end
