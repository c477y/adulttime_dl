# frozen_string_literal: true

module AdultTimeDL
  module Net
    class AlgoliaCredentialsBrowser < Base
      include BrowserSupport
      include Utils

      attr_reader :algolia_application_id, :algolia_api_key

      API_KEY_REGEXES = [/algoliasearch\("(?<application_id>\w+)","(?<api_key>\w+)"\)/x].freeze

      def initialize(config, site)
        @site = site
        @config = config
        set_algolia_params
        super()
      end

      private

      attr_reader :javascript, :config, :site

      def set_algolia_params
        fetch_javascript
        match = extract_algolia_credentials!
        @algolia_application_id = match[:application_id]
        @algolia_api_key = match[:api_key]
        AdultTimeDL.logger.debug "Extracted Algolia Params: " \
          "Application ID: #{algolia_application_id}, API Key: #{algolia_api_key}"
      end

      def extract_algolia_credentials!
        raise FatalError, "Unable to load javascript that contains algolia credentials" if javascript.nil?

        match_regex = API_KEY_REGEXES.select { |x| javascript.match?(x) }.first
        raise FatalError, "Unable to fetch algolia credentials from javascript" unless match_regex

        javascript.match(match_regex)
      end

      def fetch_javascript
        cookie(site, config.cookie) if config.cookie_file

        request(headless: !config.verbose) do |driver, wait|
          driver.intercept do |request, &continue|
            uri = URI.parse(request.url)
            if uri.path&.end_with?("slickadd.min.js")
              continue.call(request) do |response|
                @javascript = response.body
              end
            else
              continue.call(request)
            end
          end
          AdultTimeDL.logger.debug "Requesting webpage #{@site}"
          driver.get(@site)
          wait.until { !javascript.nil? }
        end
      end
    end
  end
end
