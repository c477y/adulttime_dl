# frozen_string_literal: true

module XXXDownload
  module Data
    class HouseOFyreScene < Net::Base
      attr_reader :url, :doc, :cookie

      include HTTParty

      # EXAMPLE:
      # MP4 1080p (1799.6 MB)
      # MP4 720p (1158.3 MB)
      # MP4 480p (701.7 MB)
      # rubocop:disable Lint/MixedRegexpCaptureTypes
      DOWNLOAD_TEXT_REGEX = /
        (?<format>MP4)                   # Format
        \s                               # Separator
        (?<resolution>(\d{3,4}p)|4K)     # Resolution
        \s\(                             # Separator
        (?<size>[\w\s.]+)                # File size
        \)                               # Separator
        /x
      # rubocop:enable Lint/MixedRegexpCaptureTypes

      def initialize(url, cookie)
        @url = url
        @cookie = cookie
        super()
      end

      def process
        @doc = fetch
        scene = {}.tap do |h|
          h[:title] = title
          h[:actors] = actors
          h[:release_date] = release_date
          h[:network_name] = "HouseOFyre"
          h[:download_sizes] = download_sizes
          h[:downloading_links] = downloading_links
          h[:collection_tag] = "HF"
          h[:is_streamable] = false # Force use download strategy
        end
        Data::Scene.new(scene)
      end

      private

      def title
        doc.css(".content_wrapper .title_bar").text.strip
      end

      def actors
        actors = doc.css(".update_models").first.css("a").map { |x| x.text.strip }.sort
        actors.map { |actor| Data::Actor.new(name: actor, gender: "unknown") }
      end

      def release_date
        date = doc.css(".gallery_info .update_date").first&.text&.strip

        Time.strptime(date, "%m/%d/%Y").strftime("%Y-%m-%d")
      end

      def download_sizes
        doc.css("#download_options_block .downloaddropdown li")[1..].css("a").map { |x| resolution(x) }
      end

      def resolution(sub_doc)
        sub_doc.text.strip.match(DOWNLOAD_TEXT_REGEX)&.[]("resolution")
      end

      def downloading_links
        hash = {}
        hash["default"] = []
        doc.css("#download_options_block .downloaddropdown li")[1..].css("a").map do |x|
          hash["res_#{resolution(x)}"] = x["href"]
          hash["default"] << x["href"]
        end
        hash
      end

      def downloading_link(sub_doc)
        hash = {}

        sub_doc&.css("a")&.map do |x|
          hash["res_#{resolution(x)}"] = x["href"]
          hash["default"] << x["href"]
        end
      end

      def fetch
        http_resp = HTTParty.get(url, headers:, follow_redirects: false)
        resp = handle_response!(http_resp, return_raw: true)
        Nokogiri::HTML(resp.body)
      end

      def headers
        default_headers.merge("Cookie" => cookie)
      end
    end
  end
end
