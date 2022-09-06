# frozen_string_literal: true

module AdultTimeDL
  module Net
    class JulesJordanDownloadLinks < Base
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
        url_element = doc.css("#download_select option")
                         .find { |x| matches_resolution?(x.text.strip) }
        if url_element.nil?
          AdultTimeDL.logger.warn "Unable to extract link from #{scene_data.title}"
          nil
        else
          url_element.attr("value")
        end
      end

      private

      RESOLUTION_STR = /-\s+-\s(?<resolution>\w+)\s-\sSCENE/x.freeze
      RES_MAP = {
        "4k" => "4k",
        "1080p" => "fhd",
        "720p" => "hd",
        "360p" => "sd",
        "MOBILE" => "sd"
      }.freeze

      attr_reader :config

      def matches_resolution?(res)
        match = RESOLUTION_STR.match(res)

        return false if ["", "Choose Format"].include?(res)

        if match.nil?
          AdultTimeDL.logger.debug "julesjordan: no resolution extracted from: #{res} "
          false
        else
          res = match[:resolution].downcase
          return true if config.quality == RES_MAP[res]
        end
        false
      end

      def fetch_webpage(url)
        http_resp = HTTParty.get(url, headers: headers, return_raw: true)
        resp = handle_response!(http_resp, return_raw: true)
        doc = Nokogiri::HTML(resp.body)
        if doc.title.strip == "New Device Activation"
          msg = "Request blocked by new device activation page. Clear the bypass and try again."
          raise RedirectedError.new(endpoint: url, code: http_resp.code,
                                    body: msg, headers: http_resp.headers)
        elsif doc.title.end_with?("Members Login")
          raise RedirectedError.new(endpoint: actor_page, code: http_resp.code,
                                    body: http_resp.parsed_response, headers: http_resp.headers)
        else
          doc
        end
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
