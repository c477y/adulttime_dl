# frozen_string_literal: true

module XXXDownload
  module Net
    module Refreshers
      class Bellesa < BaseRefresh
        TAG = "BELLESA_REFRESH"

        # @return [Data::Scene]
        def refresh
          raise NotImplementedError, "#{self.class.name} does not implement the method refresh"
        end
      end
    end
  end
end
