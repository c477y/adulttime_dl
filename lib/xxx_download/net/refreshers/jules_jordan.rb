# frozen_string_literal: true

module XXXDownload
  module Net
    module Refreshers
      class JulesJordan < BaseRefresh
        include Net::BrowserSupport
        include Net::SiteAuthenticationHandler
        include Utils

        TAG = "JULES_JORDAN_REFRESH"
        LOGIN_ENDPOINT = "/members"

        # Example resolution map for a scene
        # The regex should filter all the unsupported downloads (mobile and trailer)
        #
        # 720P (899.67mb)
        # 1080P (1.85gb)
        # 4K (6.13gb)
        # 480P (544.22mb)
        # 360P (336.99mb)
        # MOBILE (360.19mb)
        # 720P TRAILER (41.15mb)
        # 1080P TRAILER (81.06mb)
        # 480P TRAILER (21.54mb)
        # MOBILE TRAILER (10.69mb)
        RES_MAP = /(?<res>(720P|1080P|4K|480P|360P)) \(\d+\.\d+\wb\)/ # rubocop:disable Lint/MixedRegexpCaptureTypes

        # @param [String] path Path to the scene starting with "/scenes"
        #   e.g. /scenes/Manuel-Goes-On-An-Expedition-Into-Kylie-Pages-Amazing-Curves_vids.html
        # @raise [ArgumentError] if the path does not start with "/scenes"
        def initialize(path)
          raise ArgumentError, "expected path(#{path}) to start with '/scenes'" unless path.start_with?("/scenes")

          self.class.base_uri Net::JulesJordanIndex::BASE_URI

          path = "#{LOGIN_ENDPOINT}#{path}"
          @path = path
          super()
        end

        def refresh
          @doc = fetch_doc
          scene = {}.tap do |h|
            h[:title] = title
            h[:actors] = actors
            h[:release_date] = release_date if release_date
            h[:network_name] = network_name
            h[:download_sizes] = download_sizes
            h[:downloading_links] = downloading_links
            h[:collection_tag] = "JJ"
            h[:tags] = tags
            h[:is_streamable] = false # Force use download strategy
            h[:video_link] = File.join(self.class.base_uri, path)
          end
          Data::Scene.new(scene.merge(Data::Scene::NOT_LAZY))
        end

        private

        attr_reader :path, :doc

        def title
          doc.css(".movie_title").text.strip
        end

        def actors
          doc.css(".player-scene-description .update_models a")
             .map(&:text)
             .map(&:strip)
             .map { |x| Data::Actor.new(name: x, gender: "unknown") }
        end

        def network_name
          movie = doc.css(".player-scene-description")
                     .find { |x| x.text.strip.start_with?("Movie:") }
          return "JulesJordan" unless movie

          movie.text.gsub("Movie:", "").strip
        end

        # @return [String, NilClass]
        def release_date
          date = doc.css(".player-scene-description")
                    .find { |x| x.text.strip.downcase.start_with?("date") }
          return unless date

          date = date.text.downcase.gsub("date:", "").strip
          parse_time(date, "%m/%d/%Y")
        end

        def download_sizes
          links.map { |x| x.text.strip.match(RES_MAP)[:res] }
        end

        def downloading_links
          hash = {}
          # initialise the default list in case resolution parsing doesn't match anything
          hash["default"] = []

          links.each do |x|
            res = x.text.strip.match(RES_MAP)[:res]&.downcase
            hash["res_#{res}"] = x.attr("data-video-path")
            hash["default"] << x.attr("data-video-path")
          end
          # Reverse the default array to make highest resolution first in the array
          hash["default"] = hash["default"].reverse
          # noinspection RubyMismatchedArgumentType
          Data::StreamingLinks.new(hash)
        end

        # @return [Nokogiri::XML::Element]
        def links
          @links ||= doc.css(".download-container #download-selector .download-item")
                        .select { |x| x.text.strip.match?(RES_MAP) }
        end

        def tags
          tags_doc = doc.css(".player-scene-description")
                        .find { |x| x.text.strip.downcase.start_with?("tags") }
          return [] unless tags_doc

          tags_doc.css("a").map(&:text).map(&:strip)
        end

        def fetch_doc
          ensure_cookies!
          resp = handle_response!(return_raw: true, handle_errors: false) do
            self.class.get(path, follow_redirects: false)
          end
          doc = Nokogiri::HTML(resp.body)

          if new_device_activation?(doc)
            XXXDownload.logger.info "[#{TAG}] IP blocked detected due to new device. Spawning a new browser window."
            XXXDownload.logger.info "[#{TAG}] Please check your mail, and insert the code in your browser."
            handle_new_device_activation
            fetch_doc
          end
          doc
        end

        def handle_new_device_activation
          wait_timeout(1_000)
          cookie(self.class.base_uri, @cookies)
          request do |driver, wait|
            driver.get(self.class.base_uri + path)

            wait.until { new_device_activation_complete?(driver.title) }

            cookies_arr = driver.manage.all_cookies.map do |h|
              HTTP::Cookie.new(h[:name], h[:value],
                               path: h[:path],
                               domain: h[:domain],
                               expires: h[:expires]&.to_time,
                               secure: h[:secure],
                               httponly: h[:http_only])
            end
            @cookies = persist_cookies(cookies_arr)
          end
        end

        def new_device_activation_complete?(title)
          ["Members Login", "New Device Activation"].none? { |x| title.include?(x) }
        end

        def new_device_activation?(doc)
          doc.title.match?(/New Device Activation/)
        end

        def ensure_cookies!
          @cookies = request_cookie
          self.class.headers "Cookie" => @cookies

          return unless cookie_expired?

          XXXDownload.logger.trace "[#{TAG}] Cookies expired. Re-authenticating."
          self.class.headers.delete("Cookie")
          XXXDownload.config.delete_cookie_file
          ensure_cookies!
        end

        def cookie_expired?
          resp = handle_response!(return_raw: true, handle_errors: false) do
            self.class.get("/", follow_redirects: false)
          end
          doc = Nokogiri::HTML(resp.body)

          doc.title.include?("Members Login")
        end

        def request_cookie
          # Check if cookies were persisted from a previous session
          if XXXDownload.config.cookie.present?
            XXXDownload.logger.trace "[#{TAG}] Using persisted cookies from config/previous session"
            XXXDownload.config.cookie
            # Otherwise check if the user has logged in before
          elsif !logged_in?
            XXXDownload.logger.info "[#{TAG}] Opening browser to authenticate session"
            # Attempt to authenticate
            url = File.join(self.class.base_uri, LOGIN_ENDPOINT)
            cookies_arr = authenticate(url) { |cookies| user_logged_in?(cookies) }
            persist_cookies(cookies_arr)
          end
        end

        def persist_cookies(cookies_arr)
          XXXDownload.logger.extra "[#{TAG}] Got cookies #{cookies_arr}"
          XXXDownload.config.store_cookies(cookies_arr)
          cookie = HTTP::Cookie.cookie_value(cookies_arr)
          XXXDownload.logger.extra "[#{TAG}] Set session cookies #{cookie}"
          cookie
        end

        # @param cookies [Array[Hash]] cookies a list of selenium cookies
        # @return [Boolean]
        def user_logged_in?(cookies)
          return false if cookies.nil? || cookies.empty?

          cookies.any? { |x| x[:name]&.starts_with?("pcar") }
        end

        def logged_in?
          @cookies ||= []
          @cookies.length.positive?
        end
      end
    end
  end
end
