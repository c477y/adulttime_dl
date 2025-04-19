# frozen_string_literal: true

module XXXDownload
  module Net
    module Refreshers
      # Remove the Refresh from the class name
      class EvilAngelRefresh < BaseRefresh
        TAG = "EVILANGEL_REFRESH"

        def refresh(**opts)
          raise NotImplementedError, "#{self.class.name} does not implement the method refresh"
        end
      end
    end
  end
end
