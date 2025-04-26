# frozen_string_literal: true

module XXXDownload
  module Net
    module Refreshers
      class ThePornBunny < BaseRefresh
        TAG = "THE_PORN_BUNNY_REFRESH"
        BASE_URI = "https://www.thepornbunny.com"

        include BrowserSupport

        # @param [String] path Path to the scene starting with "/video"
        #   e.g. /video/serving-hot-pie-to-the-neighbor/
        # @raise [ArgumentError] if the path does not start with "/video"
        def initialize(path)
          @path = path

          validate_path!

          super()
        end

        # @return [Data::Scene]
        # noinspection RubyMismatchedReturnType
        def refresh(**opts)
          setup
          load_interceptor

          @doc = fetch_video_page!(full_path)

          if links.empty? || doc.nil?
            XXXDownload.logger.warn "[#{TAG}] No video link found"
            return empty_scene
          end

          teardown
          to_scene(links.first)
        rescue ::Net::ReadTimeout
          teardown!
          refresh
        end

        def inspect = "#<#{self.class.name} path=#{path}>"

        private

        attr_reader :path, :doc

        def full_path = @full_path ||= File.join(BASE_URI, path)
        def empty_scene = Data::Scene.fail_scene(full_path)

        def validate_path!
          return if path.start_with?("/video")

          raise ArgumentError, "expected path(#{path}) to start with '/video'"
        end

        def load_interceptor
          driver.intercept do |request, &continue|
            XXXDownload.logger.extra "[#{TAG}] Intercepting request: #{request.url}"

            uri = URI.parse(request.url)
            if uri.host == "cdn.jsdelivr.net"
              XXXDownload.logger.debug "[#{TAG}] Blocked request to Disable-Devtools"
              continue.call(request) do |response|
                response.headers = { "Content-Type" => "text/plain" }
                response.body = ""
              end
            elsif uri.path&.start_with?("/get_stream")
              XXXDownload.logger.debug "[#{TAG}] Intercepting stream request: #{request.url}"
              links << request.url
            else
              continue.call(request)
            end
          rescue Selenium::WebDriver::Error::WebDriverError => e
            XXXDownload.logger.error "[INTERCEPTOR ERROR] #{e}"
          end
        end

        # @param [String] page
        # @return [Nokogiri::HTML4::Document, nil]
        def fetch_video_page!(page)
          request(teardown_browser: false, add_cookies: false) do
            XXXDownload.logger.debug "[#{TAG}] Fetching #{page}"
            driver.get(page)

            unless page == driver.current_url
              XXXDownload.logger.warn "[#{TAG}] Redirected to #{driver.current_url}"
              return
            end

            wait.until { driver.find_element(class: "fp-play").displayed? }
            driver.find_element(class: "fp-play").click

            wait.until { links.length.positive? }

            return Nokogiri::HTML(driver.page_source)
          end
        rescue Selenium::WebDriver::Error::NoSuchWindowError
          raise FatalError, "Browser window was closed"
        end

        def to_scene(cdn_link)
          new_cdn_link = download_link(cdn_link)

          resp = handle_response!(handle_errors: false) { self.class.get(new_cdn_link, follow_redirects: false) }
          download_location = case resp.code
                              when 302 then resp.headers["Location"]
                              else
                                XXXDownload.logger.warn "[#{TAG}] Unexpected response code: #{resp.code} " \
                                                        "with content type #{resp.headers["Content-Type"]}"
                                XXXDownload.logger.trace "[#{TAG}] Response body: #{resp.body}"
                                nil
                              end
          return empty_scene unless download_location.present?

          Data::Scene.new(
            scene_hash.merge(downloading_links: Data::StreamingLinks.with_single_url(download_location))
                      .merge(Data::Scene::NOT_LAZY)
          )
        end

        def scene_hash
          {}.tap do |h|
            h[:video_link] = full_path
            h[:title] = title
            h[:actors] = actors
            h[:network_name] = network_name
            h[:collection_tag] = "TPB"
            h[:tags] = tags
            h[:duration] = duration if duration
            h[:download_sizes] = download_sizes
          end
        end

        #
        # Replace the resolution in the CDN link with the one specified in the config
        #
        # @param [String] cdn_link The CDN link that contains the video
        # @return [String] The modified CDN link with the resolution replaced
        def download_link(cdn_link)
          uri = URI(cdn_link)

          unless uri.path.end_with?(".mp4")
            XXXDownload.logger.warn "[#{TAG}] Download link does not appear to be of a mp4 file: #{cdn_link}"
            return cdn_link
          end

          original_resolution = uri.path.match(/\d+-(\d+)\.mp4$/)&.[](1)
          XXXDownload.logger.trace "[#{TAG}] Video resolution: #{original_resolution}"
          return cdn_link unless override_resolution.present?

          XXXDownload.logger.trace "[#{TAG}] Overriding resolution: #{override_resolution}"
          cdn_link.sub(/(\d+-)(#{original_resolution})(\.mp4)/, "\\1#{override_resolution}\\3")
        end

        #
        # Return the resolution to override the video link with
        #
        # @return [String, nil]
        def override_resolution # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          @override_resolution ||=
            if download_sizes.include?("360") && XXXDownload.config.quality == "sd"
              "360"
            elsif download_sizes.include?("720") && XXXDownload.config.quality == "hd"
              "720"
            elsif download_sizes.include?("1080") && XXXDownload.config.quality == "fhd"
              "1080"
            end
        end

        def title          = doc.at_css(".video h1").text
        def actors         = doc.css(".models .ch-title").map { |x| Data::Actor.unknown(x.text) }
        def network_name   = doc.at_css(".studios .ch-title").text
        def tags           = doc.css(".video-categories-list a").map(&:text)
        def download_sizes = @download_sizes ||= doc.css(".fp-settings-list-item a").map { |x| x.text.delete("p") }

        def duration
          doc.css(".video-stats > div")
             .find { |div| div.text.include?("Duration:") }
             &.text&.gsub(/.*?(\d+:\d+).*/, '\1')
             &.presence
        end
      end
    end
  end
end
