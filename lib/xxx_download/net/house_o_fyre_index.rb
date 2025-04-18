# frozen_string_literal: true

require_relative "../data/house_o_fyre_scene"

module XXXDownload
  module Net
    class HouseOFyreIndex < BaseIndex
      MEMBERS_URL = "https://houseofyre.elxcomplete.com/access/"

      # For scenes
      # Trial website URL:   https://houseofyre.com/updates/Twerknado-Avery-Jane.html
      # Members website URL: https://houseofyre.elxcomplete.com/access/scenes/Twerknado-Avery-Jane_vids.html
      def search_by_all_scenes(url)
        url = sanitize_scene_url(url)
        Data::Scene.new(placeholder_scene_hash.merge(video_link: url, refresher: Data::HouseOFyreScene))
      end

      # For actors
      # Trial website URL:   https://houseofyre.com/models/AlexisFawx.html
      # Members website URL: https://houseofyre.elxcomplete.com/access/models/AlexisFawx.html
      def search_by_actor(url)
        url = sanitize_actors_url(url)
        fetch_all_scenes(url).map do |x|
          Data::Scene.new(placeholder_scene_hash.merge(video_link: x, refresher: Data::HouseOFyreScene))
        end
      end

      private

      def fetch_all_scenes(url, accumulator = [])
        XXXDownload.logger.info "[FETCH URL] #{url}"
        doc = fetch(url)

        doc.css(".category_listing_block .category_listing_wrapper_updates").map do |m_doc|
          next if paid_scene?(m_doc)

          scene = m_doc.css("a").map { |x| x["href"] }.first
          XXXDownload.logger.debug "[ADD URL] #{scene}"
          accumulator << scene
        end

        if reached_end_of_pagination?(doc)
          XXXDownload.logger.debug "[REACHED END OF PAGES]"
          accumulator
        else
          next_page = next_page(doc)
          fetch_all_scenes(next_page, accumulator)
        end
      end

      def next_page(doc)
        active_reached = false
        doc.css(".global_pagination li").map do |li|
          if active_reached
            path = li.css("a").map { |x| x["href"] }.first
            return "#{MEMBERS_URL}#{path}"
          end
          active_reached = true if li.attr("class") == "active"
        end
      end

      def paid_scene?(m_doc)
        !m_doc.css(".cart_buttons").empty?
      end

      def reached_end_of_pagination?(doc)
        doc.css(".global_pagination").empty? ||
          doc.css(".global_pagination li").last.attr("class") == "active"
      end

      def sanitize_scene_url(url)
        changed_path = url.gsub("houseofyre.com", "houseofyre.elxcomplete.com")
                          .gsub("/updates/", "/access/scenes/")
        changed_path.include?("_vids.html") ? changed_path : changed_path.gsub(".html", "_vids.html")
      end

      def sanitize_actors_url(url)
        path_modified = url.include?("houseofyre.com") ? url.gsub("/models/", "/access/models/") : url
        path_modified.gsub("houseofyre.com", "houseofyre.elxcomplete.com")
      end

      def fetch(url)
        http_resp = HTTParty.get(url, headers:, follow_redirects: false)
        resp = handle_response!(http_resp, return_raw: true)
        Nokogiri::HTML(resp.body)
      end

      def headers
        default_headers.merge("Cookie" => config.cookie)
      end
    end
  end
end
