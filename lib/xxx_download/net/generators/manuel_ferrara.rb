# frozen_string_literal: true

module XXXDownload
  module Net
    module Generators
      class ManuelFerrara < JulesJordanMedia
        BASE_URL = "https://manuelferrara.com"

        def initialize(config)
          super(config, BASE_URL)
        end
      end
    end
  end
end
