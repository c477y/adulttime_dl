# frozen_string_literal: true

module AdultTimeDL
  module Net
    class ArchAngelDownloadLinks < Base
      include HTTParty
      include ResolutionHelper

      ARCH_ANGEL_VIDEO = "archangelvideo.com"
      ARCH_ANGEL_WORLD = "archangelworld.com"

      # @param [Data::Config] config
      def initialize(config)
        @config = config
        self.class.logger AdultTimeDL.logger, :debug
        super()
      end

      # @param [Data::Scene] scene_data
      # @return [String, NilClass]
      def fetch(scene_data)
        res_hash = {}
        if scene_data.video_link.include?(ARCH_ANGEL_VIDEO)
          doc = fetch_webpage(scene_data.video_link)
          base_url = base_url(scene_data.video_link)

          doc.css("#download_options_block .dropdown li a").map do |elem|
            res_hash[elem.text.strip] = File.join(base_url, elem["href"])
          end
        elsif scene_data.video_link.include?(ARCH_ANGEL_WORLD)
          doc = fetch_webpage(scene_data.video_link)
          base_url = base_url(scene_data.video_link)
          doc.css("#download_select option").map do |elem|
            next if elem["value"] == ""

            res_hash[elem.text.strip] = File.join(base_url, elem["value"])
          end
        end
        matched_url(res_hash)
      end

      private

      attr_reader :config

      def base_url(url)
        uri = URI.parse(url)
        "#{uri.scheme}://#{uri.host}"
      end

      def fetch_webpage(url)
        resp = handle_response!(HTTParty.get(url, headers: headers), return_raw: true)
        Nokogiri::HTML(resp.body)
      end

      def headers
        default_headers.merge(
          "Accept" => "*/*",
          "Connection" => "keep-alive",
          "DNT" => "1",
          "Cookie" => config.cookie
        )
      end
    end
  end
end

