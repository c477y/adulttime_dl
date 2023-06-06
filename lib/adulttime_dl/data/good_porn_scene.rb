# frozen_string_literal: true

module AdultTimeDL
  module Data
    class GoodPornScene < Net::Base
      attr_reader :url, :doc

      include HTTParty

      # TITLE_REGEX = %r{
      #   (?<network_name>[\w\s_'"!?():]+)    # Network Name
      #   \s-\s                            # Separator
      #   (?<title>[\w\s_'"!?.#-]+)        # Title
      #   \s-\s                            # Separator
      #   (?<date>\d{2}/\d{2}/\d{4})       # Release Date MM/DD/YYYY
      #   }x.freeze
      #
      # TITLE_REGEX_2 = %r{
      #   -\s                              # Separator
      #   (?<title>[\w\s_'"!?.#-():]+)        # Title
      #   \s-\s                            # Separator
      #   (?<date>\d{2}/\d{2}/\d{4})       # Release Date
      # }x.freeze

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
        /x.freeze

      def initialize(url, _cookie)
        @url = url
        self.class.logger AdultTimeDL.logger, :debug
        super()
      end

      def process
        resp = handle_response_v2!(return_raw: true) { self.class.get(url, headers: default_headers) }
        @doc = Nokogiri::HTML(resp.body)
        scene = {}.tap do |h|
          h[:title] = title
          h[:actors] = actors
          h[:release_date] = release_date?
          h[:network_name] = network_name
          h[:download_sizes] = download_sizes
          h[:downloading_links] = downloading_links
          h[:collection_tag] = "GP"
          h[:is_streamable] = false # Force use download strategy
        end
        Data::Scene.new(scene)
      end

      private

      # @return [String]
      def title
        title_text_hash["title"]
      end

      # @return [Array[String]]
      def actors
        actor_doc = doc.css(".info .item").select { |x| x.text.strip.start_with?("Models:") }.first
        if actor_doc.nil?
          AdultTimeDL.logger.debug "[WARN] No actors parsed from scene #{url}"
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
        download_tags.css("a").map { |x| resolution(x) }
      end

      # @param [Nokogiri::XML::Element] res_doc
      # @return [String]
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
                           else
                             nil
                           end
            hash["title"] = split_text[1..-2].join("-").strip
            hash
          end
      end
    end
  end
end
