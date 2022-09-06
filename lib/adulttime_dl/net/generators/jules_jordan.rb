# frozen_string_literal: true

module AdultTimeDL
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
