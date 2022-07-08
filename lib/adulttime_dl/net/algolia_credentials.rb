# frozen_string_literal: true

module AdultTimeDL
  module Net
    class AlgoliaCredentials < Base
      include HTTParty

      API_KEY_REGEXES = [
        /
        {
          "algolia":
            {
              "apiKey":"(?<api_key>\w*=*)",
              "applicationID":"(?<application_id>\w*)"
            }
        }/x,
        /
        {
          "algolia":
            {
              "applicationID":"(?<application_id>\w*)",
              "apiKey":"(?<api_key>\w*=*)"
            }
        }/x
      ].freeze

      attr_reader :algolia_application_id, :algolia_api_key

      def initialize(site)
        self.class.base_uri(base_url(site))
        self.class.logger AdultTimeDL.logger, :debug
        set_algolia_params
        super()
      end

      private

      def set_algolia_params
        match = extract_algolia_credentials!
        @algolia_application_id = match[:application_id]
        @algolia_api_key = match[:api_key]
      end

      def extract_algolia_credentials!
        js = parse_homepage_script
        match_regex = API_KEY_REGEXES.select { |x| js.match?(x) }.first
        raise FatalError, "Unable to fetch algolia credentials" unless match_regex

        js.match(match_regex)
      end

      def parse_homepage_script
        doc = Nokogiri::HTML(homepage)
        doc.search("script").text
      end

      def homepage
        self.class.get("/", headers: default_headers).parsed_response
      end
    end
  end
end
