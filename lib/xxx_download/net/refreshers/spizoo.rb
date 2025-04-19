# frozen_string_literal: true

module XXXDownload
  module Net
    module Refreshers
      # Remove the Refresh from the class name
      class Spizoo < BaseRefresh
        include Utils

        TAG = "SPIZOO_REFRESH"

        def initialize(path, cookies)
          unless path.start_with?("/gallery.php")
            raise ArgumentError, "expected path(#{path}) to start with '/gallery.php'"
          end

          self.class.base_uri Net::SpizooIndex::BASE_URI
          self.class.headers "Cookie" => cookies

          @path = path
          super()
        end

        def refresh(**opts)
          fetch(path)

          scene = {}.tap do |h|
            h[:title] = title
            h[:actors] = actors
            h[:release_date] = release_date if release_date
            h[:network_name] = network_name || "Spizoo"
            h[:download_sizes] = download_sizes
            h[:downloading_links] = downloading_links
            h[:collection_tag] = "SPZ"
            h[:tags] = tags
            h[:is_streamable] = false # Force use download strategy
            h[:video_link] = File.join(self.class.base_uri, path)
          end
          Data::Scene.new(scene.merge(Data::Scene::NOT_LAZY))
        end

        private

        attr_reader :path, :doc

        def title
          doc.css("#title-video .title").text.strip
        end

        def actors
          doc.css("#title-video .models a")
             .map { |x| x["title"].strip.presence }.compact
             .map { |x| Data::Actor.new(name: x, gender: "unknown") }
        end

        def release_date
          time_str = doc.css("#information-video .date p").text.strip.presence
          return unless time_str

          parse_time(time_str, "%m/%d/%Y")
        end

        def network_name
          doc.css("#information-video .series-information a")
             .map { |x| x["title"].strip.presence }
             .compact.first
        end

        def download_sizes
          doc.css("#information-video .download .dropdown-menu .dropdown-item")
             .map { |x| x.text.strip.split.last }
        end

        def downloading_links
          hash = {}
          # initialise the default list in case resolution parsing doesn't match anything
          hash["default"] = []

          links.each do |x|
            res = x.text.strip.split.last.downcase
            hash["res_#{res}"] = x.attr("href")
            hash["default"] << x.attr("href")
          end
          # Reverse the default array to make highest resolution first in the array
          hash["default"] = hash["default"].reverse
          # noinspection RubyMismatchedArgumentType
          Data::StreamingLinks.new(hash)
        end

        def links
          doc.css("#information-video .download .dropdown-menu .dropdown-item")
        end

        def tags
          doc.css("#information-video .categories .categories-wrapper a").map { |x| x.text.strip }
        end

        def fetch(url)
          resp = handle_response!(return_raw: true) { self.class.get(url, follow_redirects: false) }
          @doc = Nokogiri::HTML(resp.body)

          msg = "Network request failed, it looks like your cookie expired / your request was blocked due" \
                "to a new IP address. Run the tool again to re-authenticate your session."
          raise FatalError, msg if session_error?

          doc
        end

        def session_error?
          ["login", "new device activation"].any? { |x| doc.title.downcase.include?(x) }
        end
      end
    end
  end
end
