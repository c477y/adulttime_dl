# frozen_string_literal: true

module XXXDownload
  module Net
    module Generators
      class JulesJordan < JulesJordanMedia
        BASE_URL = "https://www.julesjordan.com"

        # @param [XXXDownload::Data::GeneratorConfig] config
        def initialize(config)
          super(BASE_URL, config)
        end
      end
    end
  end
end
