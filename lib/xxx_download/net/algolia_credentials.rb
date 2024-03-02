# frozen_string_literal: true

module XXXDownload
  module Net
    class AlgoliaCredentials < Base
      attr_reader :algolia_application_id, :algolia_api_key

      def initialize(uri, force_login = false)
        if force_login
          login_parse_params(uri)
        else
          self.class.base_uri uri
          no_login_parse_params
        end
        super()
      end

      private

      attr_reader :force_login

      def login_parse_params(_uri)
        raise "Not Implemented"

        # request do |driver, wait|
        #   driver.get(uri)
        #   wait.until { logged_in? }
        # end
      end

      def no_login_parse_params
        js = parse_script_text

        algolia_api_key = /"apiKey":\s*"(?<api_key>\w*=*)"/.match(js)
        algolia_application_id = /"applicationID":\s*"(?<application_id>\w*)"/.match(js)

        raise FatalError, "Unable to fetch algolia credentials" unless algolia_api_key && algolia_application_id

        @algolia_api_key = algolia_api_key[:api_key]
        @algolia_application_id = algolia_application_id[:application_id]
      end

      def parse_script_text
        web_resp = handle_response!(return_raw: true) { self.class.get("/") }
        doc = Nokogiri::HTML(web_resp.body)
        doc.search("script").text
      end
    end
  end
end
