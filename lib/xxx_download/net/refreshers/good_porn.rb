# frozen_string_literal: true

module XXXDownload
  module Net
    module Refreshers
      class GoodPorn < BaseRefresh
        def initialize(path)
          @path = path.gsub(Net::GoodpornIndex::BASE_URI, "")
          self.class.base_uri Net::GoodpornIndex::BASE_URI
          super()
        end

        def refresh(**opts)
          resp = handle_response!(return_raw: true) { self.class.get(path, headers: default_headers) }
          @doc = Nokogiri::HTML(resp.body)
          scene = {}.tap do |h|
            h[:title] = title
            h[:actors] = actors
            h[:release_date] = release_date? if release_date?
            h[:network_name] = network_name
            h[:download_sizes] = download_sizes
            h[:downloading_links] = downloading_links
            h[:collection_tag] = collection_tag
            h[:tags] = tags
            h[:duration] = duration
            h[:is_streamable] = false # Force use download strategy
            h[:video_link] = File.join(self.class.base_uri, path)
          end
          Data::Scene.new(scene.merge(Data::Scene::NOT_LAZY))
        end

        private

        TAG = "GOODPORN_REFRESH"

        attr_reader :path, :doc

        # EXAMPLE:
        # MP4 1080p, 752.36 Mb
        # MP4 2160p, 2.51 Gb
        # MP4 360p, 162.37 Mb
        # MP4 480p, 224.11 Mb
        # MP4 720p, 382.75 Mb
        DOWNLOAD_TEXT_REGEX = /
        (?<format>MP4)                   # Format
        \s                               # Separator
        (?<resolution>\d{3,4}p)          # Resolution
        ,\s                              # Separator
        (?<size>\w+)                     # File size
        /x

        COLLECTION_TAG_LOOKUP = {
          "babes" => "BB",
          "brazzers" => "BZ",
          "digital playground" => "DP",
          "dogfart network" => "DGF",
          "evil angel" => "EA",
          "mofos" => "MOF",
          "reality kings" => "RK",
          "sexyhub" => "SXH",
          "twistys" => "TW"
        }.freeze

        # @return [String]
        def title
          title_text_hash["title"]
        end

        # @return [String]
        def collection_tag # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          channel_name = doc.css(".info .item")
                            .find { |x| x.text.strip.start_with?("Channel:") }
                            &.css("a")
                            &.map { |x| x.text.strip }
                            &.first
          XXXDownload.logger.warn "[WARN] No collection tag parsed from scene #{path}" if channel_name.nil?
          ct = COLLECTION_TAG_LOOKUP.fetch(channel_name&.downcase, "GP")

          XXXDownload.logger.debug "[#{TAG}] Collection Tag not configured for #{channel_name}" if ct == "GP"
          ct
        end

        # @return [NilClass, Array[String]]
        def tags
          doc.css(".info .item")
             .find { |x| x.text.strip.start_with?("Tags:") }
             &.css("a")
             &.map { |x| x.text.strip.downcase }
        end

        # @return [NilClass, String]
        def duration
          d = doc.css(".info .item span")
                 .find { |x| x.text.strip.start_with?("Duration:") }
                 &.css("em")
                 &.text&.strip
          if d.nil?
            XXXDownload.logger.warn "[#{TAG}] No duration parsed from scene #{title}"
            return
          end

          unless d.match?(/\d{1,2}:\d{2}/)
            XXXDownload.logger.warn "[#{TAG}] [#{d}] Invalid duration parsed #{title}"
            return
          end

          d
        end

        # @return [Array[String]]
        def actors
          actor_doc = doc.css(".info .item").select { |x| x.text.strip.start_with?("Models:") }.first
          if actor_doc.nil?
            XXXDownload.logger.debug "[WARN] No actors parsed from scene #{path}"
            return []
          end

          actors = actor_doc.css("a").map { |x| x.text.strip }.sort
          actors.map { |actor| Data::Actor.new(name: actor, gender: "unknown") }
        end

        # @return [String]
        def release_date?
          title_text_hash["date"].presence
        end

        # @return [String]
        def network_name
          title_text_hash["network_name"]
        end

        # @return [Array[String]]
        def download_sizes
          download_tags.css("a").map { |x| resolution(x) }.compact
        end

        # @param [Nokogiri::XML::Element] res_doc
        # @return [String, Nil]
        def resolution(res_doc)
          res_doc.text.strip.match(DOWNLOAD_TEXT_REGEX)&.[]("resolution")
        end

        # @return [Data::StreamingLinks]
        def downloading_links
          hash = {}
          # initialise the default list in case resolution parsing doesn't match anything
          hash["default"] = []
          download_tags&.css("a")&.map do |x|
            hash["res_#{resolution(x)}"] = x["href"]
            hash["default"] << x["href"]
          end
          # Reverse the default array to make highest resolution first in the array
          hash["default"] = hash["default"].reverse
          Data::StreamingLinks.new(hash)
        end

        # @return [Nokogiri::XML::Element]
        def download_tags
          doc.css(".info .item").select { |x| x.text.strip.start_with?("Download:") }.first
        end

        def title_text_hash
          @title_text_hash ||=
            begin
              split_text = doc.css(".content .headline h1").text.strip.split("-")

              hash = {}
              hash["network_name"] = split_text.first.strip.presence || "GoodPorn"
              hash["date"] = case split_text.last
                             when %r{\d{2}/\d{2}/\d{4}}
                               Time.strptime(split_text.last.strip, "%m/%d/%Y").strftime("%Y-%m-%d")
                             when /\d{8}/
                               Time.strptime(split_text.last, "%m%d%Y").strftime("%Y-%m-%d")
                             end
              hash["title"] = split_text[1..-2].join("-").strip
              hash
            end
        end
      end
    end
  end
end
