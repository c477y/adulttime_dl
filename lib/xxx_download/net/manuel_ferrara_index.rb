# frozen_string_literal: true

module XXXDownload
  module Net
    class ManuelFerraraIndex < BaseIndex
      TAG = "MANUELFERRARA_INDEX"
      BASE_URI = "https://www.manuelferrara.com"
      base_uri BASE_URI

      def search_by_all_scenes(url)
        verify_urls(url, "/scenes")
        fetch(url) # to verify the link is valid
        [create_lazy_scene(scene_link(url))]
      end

      def search_by_movie(url)
        verify_urls(url, "/dvds")
        fetch(url).css(".dvd_details .dvd_info a")
                  .map { |x| x["href"] }
                  .select { |x| x.include?("/scenes") }
                  .uniq
                  .map { |x| create_lazy_scene(scene_link(x)) }
      end

      def search_by_actor(url)
        verify_urls(url, "/models")
        fetch(url).css(".category_listing_wrapper_updates .update_details a")
                  .map { |x| x["href"] }
                  .select { |x| x.include?("/scenes") }
                  .uniq
                  .map { |x| create_lazy_scene(scene_link(x)) }
      end

      def search_by_page(url)
        verify_urls(url, "/movies")
        fetch(url).css(".category_listing_wrapper_updates .update_details a")
                  .map { |x| x["href"] }
                  .select { |x| x.include?("/scenes") }
                  .uniq
                  .map { |x| create_lazy_scene(scene_link(x)) }
      end

      def actor_name(resource)
        fetch(resource).css(".title_bar .title_bar_hilite").text.strip.presence
      end

      private

      # @param [String] url
      # @param [String] path
      def verify_urls(url, path)
        return if url.include?(path)

        XXXDownload.logger.warn "[#{TAG}] URL should be a link to #{path}. You may get unexpected results."
      end

      def create_lazy_scene(path)
        Data::Scene.new(
          video_link: path,
          refresher: Refreshers::ManuelFerrara.new(path),
          **Data::Scene::LAZY
        )
      end

      def scene_link(url)
        XXXDownload.logger.extra "[#{TAG}] Extracting scene link from #{url}"
        base_uri_without_www = BASE_URI.gsub("www.", "")
        resp = url.gsub(BASE_URI, "")
                  .gsub(base_uri_without_www, "")
                  .gsub(%r{/(members|trial)}, "")
        XXXDownload.logger.extra "[#{TAG}] Scene link: #{resp}"
        resp
      end

      def fetch(url)
        path = url.gsub(BASE_URI, "") # remove the base URL
                  .gsub("/members", "/trial") # remove the member part to bypass auth. Refreshers handles authentication
        resp = handle_response!(return_raw: true) { self.class.get(path, follow_redirects: false) }
        Nokogiri::HTML(resp.body)
      end
    end
  end
end
