# frozen_string_literal: true

module AdultTimeDL
  module Net
    class PornVEIndex < BaseIndex
      def search_by_all_scenes(url)
        doc = fetch(url)
        doc.css(".box_bodzy .vid_bloczk")
           .map { |x| make_scene_data(x) }
      end

      private

      def make_scene_data(doc)
        Data::PornVEScene.new(
          title: title(doc),
          release_date: nil,
          network_name: "PornVE",
          download_sizes: [],
          is_streamable: true,
          video_link: video_link(doc)
        )
      end

      def video_link(doc)
        doc.css("a").css(".morevids").map { |link| link["href"] }.compact.first
      end

      def title(doc)
        doc.css(".vb_title b").text.strip.gsub("&", ",")
      end

      def fetch(actor_page)
        resp = handle_response!(HTTParty.get(actor_page, headers: headers), return_raw: true)
        Nokogiri::HTML(resp.body)
      end

      def headers
        default_headers.merge(
          "Accept" => "*/*",
          "Connection" => "keep-alive",
          "DNT" => "1",
        )
      end
    end
  end
end

