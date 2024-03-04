# frozen_string_literal: true

module XXXDownload
  module Net
    module Generators
      class HTTPGenerator < BaseGenerator
        include HTTParty

        def initialize(base_uri)
          super()
          self.class.base_uri(base_uri)
          self.class.follow_redirects false
          self.class.headers = self.class.headers.merge("Cookie" => config.cookie)
        end

        private

        def fetch(url)
          resp = handle_response!(return_raw: true) { self.class.get(url) }
          Nokogiri::HTML(resp.body)
        end
      end
    end
  end
end
