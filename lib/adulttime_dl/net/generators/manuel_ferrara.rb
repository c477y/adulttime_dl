# frozen_string_literal: true

module AdultTimeDL
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
