# frozen_string_literal: true

module XXXDownload
  module Net
    module Generators
      class ManuelFerrara < JulesJordanMedia
        BASE_URL = "https://manuelferrara.com"

        def initialize(config)
          super(BASE_URL, config)
        end
      end
    end
  end
end
