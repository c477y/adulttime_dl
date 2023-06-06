# frozen_string_literal: true

module AdultTimeDL
  module Data
    class GoodPornScene < Net::Base
      attr_reader :url, :doc

      include HTTParty

      TITLE_REGEX = %r{
        ^                                # Start of String
        (?<network_name>[\w\s_'"!?]+)    # Network Name
        \s-\s                            # Separator
        (?<title>[\w\s_'"!?]+)           # Title
        \s-\s                            # Separator
        (?<date>\d{2}/\d{2}/\d{4})       # Release Date MM/DD/YYYY
        #                                # End of String
        }x.freeze

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

      def initialize(url)
        @url = url
        self.class.logger AdultTimeDL.logger, :debug
        super()
      end

      def process
        resp = handle_response!(self.class.get(url, headers: default_headers), return_raw: true)
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
        title_text_re&.[]("title")&.strip || doc.css(".content .headline h1").text.strip
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
        date = title_text_re&.[]("date")
        return if date.nil?

        Time.strptime(date, "%m/%d/%Y").strftime("%Y-%m-%d")
      end

      # @return [String]
      def network_name
        title_text_re&.[]("network_name") || "GoodPorn"
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

      # @return [MatchData]
      def title_text_re
        @title_text_re ||= doc.css(".content .headline h1").text.match(TITLE_REGEX)
      end
    end
  end
end
