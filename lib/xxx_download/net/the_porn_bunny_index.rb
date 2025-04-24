# frozen_string_literal: true

module XXXDownload
  module Net
    class ThePornBunnyIndex < BaseIndex
      TAG = "THE_PORN_BUNNY_INDEX"
      BASE_URI = "https://www.thepornbunny.com"
      base_uri BASE_URI

      #
      # e.g. https://www.thepornbunny.com/video/stuck-and-sucked/
      #
      # @param [String] url
      # @return [Array<Data::Scene>]
      # noinspection RubyMismatchedReturnType
      def search_by_all_scenes(url)
        verify_urls!(url, "/video/")
        path = url.gsub(BASE_URI, "")
        [create_lazy_scene(path)].compact
      end

      #
      # e.g. https://www.thepornbunny.com/pornstar/abella-danger/
      #
      # @param [String] url
      # @return [Array<Data::Scene>]
      def search_by_actor(url) = process_actor_with_pagination(url)

      #
      # e.g. https://www.thepornbunny.com/pornstar/abella-danger/
      #
      # @param [String] resource
      # @return [String]
      def actor_name(resource)
        verify_urls!(resource, "/pornstar/")

        uri = URI(resource)
        name = uri.path.sub(%r{^/pornstar/}, "").chomp("/")
        name.split("-").map(&:capitalize).join(" ")
      end

      private

      def create_lazy_scene(path)
        Data::Scene.new(
          video_link: path,
          refresher: Refreshers::ThePornBunny.new(path),
          **Data::Scene::LAZY
        )
      end

      # @param [String] page
      # @return [Array<Data::Scene>]
      def process_actor_with_pagination(page, accumulator = [])
        doc = page(page, follow_redirects: true)
        accumulator += video_links(doc).map { |x| create_lazy_scene(x) }

        return accumulator unless next_page?(doc)

        process_actor_with_pagination(next_page(doc), accumulator)
      end

      def video_links(doc)
        doc.css("#list_videos_common_videos_list .item a")
           .map { |x| x.attr("href") }.uniq
           .select { |x| video_link?(x) }
           .map { |x| remove_host(x) }
      end

      def video_link?(str) = str.include?("/video")
      def remove_host(str) = str.gsub(BASE_URI, "")
      def next_page(doc)   = doc.at_css(".paginator .next a")&.attr("href")
      def next_page?(doc)  = next_page(doc).present?
    end
  end
end
