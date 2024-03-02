# frozen_string_literal: true

module XXXDownload
  module Net
    class JulesJordanIndex < BaseIndex
      TAG = "JULES_JORDAN_INDEX"
      BASE_URI = "https://www.julesjordan.com"
      base_uri BASE_URI

      def search_by_all_scenes(url)
        verify_urls(url, "/scenes")
        fetch(url) # to verify the link is valid
        [create_lazy_scene(scene_link(url))]
      end

      def search_by_movie(url)
        verify_urls(url, "/dvds")
        fetch(url).css(".grid-container-scene .img-container-scene a")
                  .map { |x| x["href"] }
                  .uniq
                  .map { |x| create_lazy_scene(scene_link(x)) }
      end

      def search_by_actor(url)
        verify_urls(url, "/models")
        fetch(url).css(".grid-container .grid-item a")
                  .map { |x| x["href"] }
                  .select { |x| x.include?("/scenes") }
                  .uniq
                  .map { |x| create_lazy_scene(scene_link(x)) }
      end

      def search_by_page(url)
        verify_urls(url, "/movies")
        fetch(url).css(".grid-container .grid-item a")
                  .map { |x| x["href"] }
                  .select { |x| x.include?("/scenes") }
                  .uniq
                  .map { |x| create_lazy_scene(scene_link(x)) }
      end

      def actor_name(url)
        doc = fetch(url).css(".title-heading-content-black").first
        return nil if doc.nil?

        doc.text.strip.gsub(/\s-\sBio/, "")
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
          refresher: Refreshers::JulesJordan.new(path),
          **Data::Scene::LAZY
        )
      end

      def scene_link(url)
        url.gsub(BASE_URI, "")
           .gsub(%r{/(members|trial)}, "")
      end

      def fetch(url)
        path = url.gsub(BASE_URI, "") # remove the base URL
                  .gsub("/members", "/trial") # remove the member part to bypass auth. Refresher handles authentication
        resp = handle_response!(return_raw: true) { self.class.get(path, follow_redirects: false) }
        Nokogiri::HTML(resp.body)
      end
    end
  end
end
