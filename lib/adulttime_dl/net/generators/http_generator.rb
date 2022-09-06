module AdultTimeDL
  module Net
    module Generators
      class HTTPGenerator < BaseGenerator
        include HTTParty

        def initialize(config, url)
          super(config)
          configure_http(url)
        end

        private

        def configure_http(base_uri)
          self.class.base_uri(base_uri)
          self.class.logger AdultTimeDL.logger, :debug
          self.class.follow_redirects false
          self.class.headers headers
        end

        def fetch(url)
          http_resp = self.class.get(url)
          resp = handle_response!(http_resp, return_raw: true)
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
end

