# frozen_string_literal: true

module XXXDownload
  module Net
    module Generators
      class JulesJordan < JulesJordanMedia
        BASE_URL = "https://www.julesjordan.com"

        def initialize(config)
          super(config, BASE_URL)
        end
      end
    end
  end
end
