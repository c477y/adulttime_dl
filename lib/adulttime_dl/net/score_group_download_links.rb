# frozen_string_literal: true

module AdultTimeDL
  module Net
    class ScoreGroupDownloadLinks < Base
      include HTTParty

      # @param [Data::Config] config
      def initialize(config)
        @config = config
        self.class.logger AdultTimeDL.logger, :debug
        super()
      end

      # @param [Data::Scene] scene_data
      # @return [String, NilClass]
      def fetch(scene_data)
        doc = fetch_webpage(scene_data.video_link)
        res_hash = {}
        doc.css("#download-files .d-flex").map do |m_doc|
          res = m_doc.css(".label").text.strip
          res_hash[res.gsub(/\D/, "")] = m_doc.css("a").map { |link| link["href"] }.compact.first
        end
        res_hash.fetch(RES_MAP[config.quality], res_hash.to_a.first&.last)
      end

      private

      RES_MAP = { "fhd" => "1080",
                  "hd" => "720",
                  "sd" => "480" }.freeze

      attr_reader :config

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
