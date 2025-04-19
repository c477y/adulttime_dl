# frozen_string_literal: true

require "cgi"
require "date"

module XXXDownload
  module Net
    module Refreshers
      # Remove the Refresh from the class name
      class NewSensations < BaseRefresh
        TAG = "NEW_SENSATIONS_REFRESH"
        include BrowserSupport
        include Utils

        # @param [String] path Path to the scene starting with "/gallery.php"
        #   e.g. /gallery.php?id=7718&type=vids
        # @raise [ArgumentError] if the path does not start with "/gallery.php"
        def initialize(path)
          @path = path
          self.class.base_uri "#{Net::NewSensationsIndex::BASE_URI}/members"

          validate_path!

          super()
        end

        # @return [Data::Scene]
        # noinspection RubyMismatchedReturnType
        def refresh(web_driver: nil)
          raise FatalError, "#{TAG} requires the web-driver to refresh scenes" if web_driver.nil?

          @default_options = web_driver
          url = File.join(self.class.base_uri, path)
          @doc = fetch(url)

          scene = {}.tap do |h|
            h[:title] = title
            h[:actors] = actors
            h[:release_date] = release_date if release_date
            h[:network_name] = network_name
            h[:downloading_links] = downloading_links
            h[:collection_tag] = "NS"
            h[:is_streamable] = false # Force use download strategy
            h[:video_link] = url
          end
          Data::Scene.new(scene.merge(Data::Scene::NOT_LAZY))
        end

        private

        attr_reader :path, :doc

        def title        = doc.css(".flex-container .flex-child h4").text.strip
        def actors       = doc.css(".update_models a").map(&:text).map(&:strip).map { |x| Data::Actor.unknown(x) }

        # @return [String, nil]
        def release_date
          date = doc.css(".datePhotos span").text.strip.gsub(",", "")
          return unless date.present?

          parse_time(date, "%m/%d/%Y")
        end

        # @return [String]
        def network_name
          node = doc.at_css("span:contains('Series')")
          return "New Sensations" unless node

          node.parent.at_css("a")&.text&.strip || "New Sensations"
        end

        # @return [Data::StreamingLinks]
        # noinspection RubyMismatchedReturnType
        def downloading_links
          return @downloading_links if defined?(@downloading_links)

          @downloading_links = {}
          doc.css("#dl-format-select .dl-link a").each do |x|
            res = to_res_key(x.text.strip)
            @downloading_links[res] = x["href"] if res
          end
          @downloading_links["default"] = @downloading_links.values
          @downloading_links
        end

        # @param [String] res
        # @return [String, nil]
        def to_res_key(res)
          case res.downcase
          when /4k/ then "res_4k"
          when /\d+/ then "res_#{res}p"
          else
            XXXDownload.logger.warn "[#{TAG}] Unknown resolution: #{res}"
            nil
          end
        end

        def validate_path!
          unless path.start_with?("/gallery.php")
            raise ArgumentError, "expected path(#{path}) to start with '/gallery.php'"
          end

          url = File.join(self.class.base_uri, path)
          uri = URI(url)
          params = CGI.parse(uri.query || "")
          return if params["type"]&.first == "vids"

          raise ArgumentError, "expected path(#{path}) to belong to a video scene"
        end

        # @param [String] page
        # @return [Nokogiri::HTML4::Document]
        def fetch(page)
          request(teardown_browser: false, add_cookies: false) do
            driver.get(page)
            content = driver.find_element(class: "content_wrapper")
            html = driver.execute_script("return arguments[0].outerHTML;", content)
            return Nokogiri::HTML(html)
          end
        rescue Selenium::WebDriver::Error::NoSuchWindowError
          raise FatalError, "Browser window was closed"
        end
      end
    end
  end
end
