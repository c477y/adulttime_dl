# frozen_string_literal: true

module XXXDownload
  module Net
    module Refreshers
      class BaseRefresh < Base
        def refresh(**opts)
          raise NotImplementedError, "#{self.class.name} does not implement the method refresh"
        end
      end
    end
  end
end
