# frozen_string_literal: true

module XXXDownload
  module Net
    class PornfidelityIndex < BaseIndex
      include BrowserSupport

      TAG = "PORNFIDELITY_INDEX"
      BASE_URI = "https://members.kellymadisonmedia.com"
      base_uri BASE_URI

      #
      # - Sets cookie to browser
      # - Sets cookie to HTTParty
      # - Starts the browser session
      #
      def initialize
        cookie(BASE_URI, cookies)
        wait_timeout(600) # 5 minutes
        self.class.headers "Cookie" => cookies

        start_browser
        load_interceptor

        super()
      end

      # @param [String] url The URL to search for scenes, expected to reference episodes.
      # @return [Array<Data::Scene>] An array of fetched scene data
      # @raise [FatalError] If the URL is invalid or does not meet the required conditions.
      def search_by_all_scenes(url)
        verify_urls!(url, "/episodes")
        [fetch(url)].compact
      end

      # @param [String] url The URL to search for scenes, expected to reference episodes.
      # @return [Array<Data::Scene>] An array of fetched scene data
      # @raise [FatalError] If the URL is invalid or does not meet the required conditions.
      def search_by_actor(url)
        verify_urls!(url, "/models")

        # some cards just have a gallery and no scenes
        scenes_doc = page(url).css(".episode")
                              .select { |x| x.css(".media-content .subtitle").last.text.include?("min") }

        scenes_doc.map { |scene| scene.css(".media-content .title a").first.attributes["href"].value }
                  .uniq
                  .map { |x| fetch(x) }
                  .compact
      end

      # @param [String] resource
      # @return [String]
      # @raise [FatalError]
      def actor_name(resource)
        uri = URI(resource)
        raise FatalError, "[#{TAG}] Malformed URL #{resource}" if uri.path.blank?

        uri.path
           .split("/")
           .last
           .split(/[_-]/)
           .map(&:capitalize)
           .join(" ")
      end

      def cleanup
        teardown
      end

      private

      # @param [String] url
      # @param [String] path
      # @raise [FatalError] if the url is invalid or does not start with BASE_URI
      def verify_urls!(url, path)
        uri = URI(url)
        base_matches = uri.scheme && uri.host && "#{uri.scheme}://#{uri.host}" == BASE_URI
        raise FatalError, "[#{TAG}] URL must start with #{BASE_URI}" unless base_matches

        return if uri.path&.include?(path)

        XXXDownload.logger.warn "[#{TAG}] URL should be a link to #{path}. You may get unexpected results."
      rescue URI::InvalidURIError
        raise FatalError, "[#{TAG}] Invalid URL #{url}"
      end

      # @param [String] video_link
      # @param [Integer] count
      # @param [Integer] max
      # @return [Boolean]
      def navigate_to_video_link!(video_link, count: 1, max: 5)
        XXXDownload.logger.debug "[#{TAG}] Navigating to #{video_link} (attempt #{count})"
        driver.get(video_link)
        sleep(2)

        msg = "[#{TAG}] Cookies expired or invalid. Unable to navigte to #{video_link}"
        return true if driver.current_url == video_link
        raise SafeExit, msg if count > max && driver.current_url.ends_with?("login")
        return false if count > max

        navigate_to_video_link!(video_link, count: count + 1, max:)
      rescue Selenium::WebDriver::Error::UnexpectedAlertOpenError => e
        begin
          XXXDownload.logger.debug "[#{TAG}] Page opened alert with message: #{e}"
          driver.switch_to.alert.accept
          navigate_to_video_link!(video_link, count: count + 1, max:)
        rescue Selenium::WebDriver::Error::NoSuchAlertError
          navigate_to_video_link!(video_link, count: count + 1, max:)
        end
      end

      def load_interceptor
        driver.intercept do |request, &continue|
          XXXDownload.logger.extra "[#{TAG}] Intercepting request: #{request.url}"
          uri = URI.parse(request.url)
          if uri.path&.match?(%r{stream/video/\d+})
            XXXDownload.logger.debug "[#{TAG}] Intercepted video link: #{request.url}"
            links << request.url
          end
          continue.call(request)
        rescue Selenium::WebDriver::Error::WebDriverError => e
          XXXDownload.logger.error "[INTERCEPTOR ERROR] #{e}"
        end
      end

      # @param [String] video_link
      # @return [Data::Scene, nil]
      # noinspection RubyMismatchedReturnType
      def fetch(video_link)
        scene_data = {}
        request(teardown_browser: false, add_cookies: false) do
          navigate_to_video_link!(video_link)

          content = driver.find_element(id: "site-content")
          html = driver.execute_script("return arguments[0].outerHTML;", content)
          doc = Nokogiri::HTML(html)
          scene_data = make_scene_data(doc.css(".container")[2].css("ul li"))

          wait.until { links.length.positive? }
        end

        download_link = download_link(links.last)
        if download_link.nil?
          XXXDownload.logger.warn "[#{TAG}] Unable to get the download link for #{video_link}"
          return
        end

        scene_data = scene_data.merge(
          downloading_links: Data::StreamingLinks.with_single_url(download_link),
          video_link:
        )
        reset_links
        data = Data::Scene.new(scene_data)
        XXXDownload.logger.info "[#{TAG}] Fetched scene #{data.title}"
        data
      rescue Selenium::WebDriver::Error::NoSuchWindowError
        raise FatalError, "Browser window was closed"
      end

      # @param [String] path
      # @return [String, nil]
      def download_link(path)
        resp = handle_response!(return_raw: true, handle_errors: false) do
          self.class.get(path, follow_redirects: false)
        end
        return unless resp.code == 302

        resp.headers["Location"]
      end

      def make_scene_data(doc)
        {
          title: title(doc),
          actors: actors(doc),
          network_name: network_name(doc),
          collection_tag: "PF",
          release_date: release_date(doc)
        }.merge(Data::Scene::NOT_LAZY).compact
      end

      # rubocop:disable Layout/LineLength
      def node(doc, start_with) = doc.find { |x| x.text.strip.start_with?(start_with) }
      def title(doc)        = node(doc, "Title").text.gsub("Title:", "").strip
      def network_name(doc) = node(doc, "Site").text.strip.match(/^Site: (?<site_name>\w+) #\d+$/)&.[](:site_name) || "Pornfidelity"
      def release_date(doc) = node(doc, "Published")&.text&.gsub("Published:", "")&.strip
      def actors(doc)       = node(doc, "Starring")&.css("a")&.map { |x| x.text.strip }&.sort&.map { |x| Data::Actor.unknown(x) }
      # rubocop:enable Layout/LineLength

      def cookies
        @cookies ||=
          begin
            cookies = XXXDownload.config.cookie

            if cookies.include?("defaultResolution=")
              cookies.gsub(/defaultResolution=[^;]+/) do |match|
                quality = match.split("=").last
                override = XXXDownload.config.quality == "fhd" ? "1080p" : "720p"
                if quality == override
                  XXXDownload.logger.info "[#{TAG}] Quality set to #{quality}"
                  match
                else
                  XXXDownload.logger.info "[#{TAG}] Quality set to #{override}"
                  "defaultResolution=#{override}"
                end
              end
            else
              quality = XXXDownload.config.quality == "fhd" ? "1080p" : "720p"
              cookies << "; defaultResolution=#{quality}"
            end
          end
      end
    end
  end
end
