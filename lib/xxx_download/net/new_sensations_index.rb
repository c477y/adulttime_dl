# frozen_string_literal: true

module XXXDownload
  module Net
    class NewSensationsIndex < BaseIndex
      TAG = "NEW_SENSATIONS_INDEX"
      BASE_URI = "https://newsensations.com"
      base_uri BASE_URI

      include BrowserSupport

      def initialize
        super()

        cookie(BASE_URI, XXXDownload.config.cookie)
        wait_timeout(600) # 5 minutes

        start_browser
      end

      # @param [String] url
      # @return [Array<Data::Scene>]
      # noinspection RubyMismatchedReturnType
      def search_by_all_scenes(url)
        verify_urls!(url, "/gallery")
        path = url.gsub("#{BASE_URI}/members", "")
        [create_lazy_scene(path)].compact
      end

      # @param [String] url
      # @return [Array<Data::Scene>]
      # noinspection RubyMismatchedReturnType
      def search_by_movie(url)
        verify_urls!(url, "/dvds")
        doc = fetch(url)
        doc.css(".dvdScenes .dvdScene h2 a")
           .map { |x| x.attributes["href"].value }.uniq
           .map { |x| ensured_leading_slash(x) }
           .map { |x| create_lazy_scene(x) }
      end

      # @param [String] url
      # @return [Array<Data::Scene>]
      # noinspection RubyMismatchedReturnType
      def search_by_actor(url)
        verify_urls!(url, "/sets")
        doc = fetch(url)
        doc.css(".videoArea .videoBlock a")
           .map { |x| x.attributes["href"].value }
           .select { |x| include_vids?(x) }.uniq
           .map { |x| ensured_leading_slash(x) }
           .map { |x| create_lazy_scene(x) }
      end

      # @param [String] resource
      # @return [String]
      def actor_name(resource)
        doc = fetch(resource)
        name = doc.css(".modelBioBlock .modelBioContent .modelBC h3").first&.text&.strip
        return name if name.present?

        XXXDownload.logger.warn "[#{TAG}] Unable to find actor name for #{resource}"
        "New Sensations"
      end

      def cleanup = teardown

      private

      def include_vids?(path) = path.include?("type=vids")
      def ensured_leading_slash(path) = path.start_with?("/") ? path : "/#{path}"

      def create_lazy_scene(path)
        Data::Scene.new(
          video_link: path,
          refresher: Refreshers::NewSensations.new(path),
          **Data::Scene::LAZY
        )
      end

      # @param [String] page
      # @return [Nokogiri::HTML4::Document]
      def fetch(page)
        request(teardown_browser: false, add_cookies: false) do
          XXXDownload.logger.debug "[#{TAG}] Fetching #{page}"
          driver.get(page)
          raise FatalError, "[SESSION EXPIRED] Please refresh your cookies and try again" if on_login_page?

          content = driver.find_element(class: "content_wrapper")
          html = driver.execute_script("return arguments[0].outerHTML;", content)
          return Nokogiri::HTML(html)
        end
      rescue Selenium::WebDriver::Error::NoSuchWindowError
        raise FatalError, "Browser window was closed"
      end

      def on_login_page?
        content = driver.page_source
        doc = Nokogiri::HTML(content)
        doc.at_css('form[action="/auth.form"]').present?
      end
    end
  end
end
