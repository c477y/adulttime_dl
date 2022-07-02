# frozen_string_literal: true

module AdultTimeDL
  module Net
    class AlgoliaCredentials < Base
      include HTTParty
      base_uri "https://www.adulttime.com"
      logger AdultTimeDL.logger, :debug, :xxx

      API_KEY_REGEX = /
        {
          "algolia":
            {
              "apiKey":"(?<api_key>\w*)",
              "applicationID":"(?<application_id>\w*)"
            }
        }/x.freeze

      attr_reader :algolia_application_id, :algolia_api_key

      def initialize
        set_algolia_params
        super
      end

      private

      def set_algolia_params
        match = extract_algolia_credentials!
        @algolia_application_id = match[:application_id]
        @algolia_api_key = match[:api_key]
      end

      def extract_algolia_credentials!
        js = parse_homepage_script
        match = js.match(API_KEY_REGEX)
        raise FatalError, "Unable to fetch algolia credentials" if match.nil?

        match
      end

      def parse_homepage_script
        doc = Nokogiri::HTML(adulttime_homepage)
        doc.search("script").text
      end

      def adulttime_homepage
        self.class.get("/", headers: default_headers).parsed_response
      end
    end
  end
end
