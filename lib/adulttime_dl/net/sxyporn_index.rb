# frozen_string_literal: true

module AdultTimeDL
  module Net
    class SxyPornIndex < BaseIndex
      def search_by_all_scenes(url)
        doc = fetch(url)
        make_scene_data(doc)
      end

      private

      def make_scene_data(doc)
        Data::UnknownActorGenderScene.new(
          clip_id: -1,
          title: title(doc),
          actors: actors(doc),
          release_date: nil,
          network_name: "SxyPorn",
          movie_title: title(doc),
          download_sizes: [],
          is_streamable: true,
          video_link: url
        )
      end

      def title(doc)
        txt = doc.at_xpath('//div[@class="post_text"]/text()').text.strip
        txt.gsub(/^-/, "").strip
      end

      def actors(doc)
        doc.css(".post_el_small").first.css(".post_text a.ps_link")
           .map { |x| x.text.strip.gsub(",", "") }
           .map { |x| Data::Actor.new(name: x, gender: "unknown") }
      end

      def fetch(url)
        resp = handle_response!(HTTParty.get(url), return_raw: true)
        Nokogiri::HTML(resp.body)
      end
    end
  end
end
