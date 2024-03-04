# frozen_string_literal: true

module XXXDownload
  module Net
    module Generators
      class BaseGenerator < Base
        attr_reader :config

        def actors(_female_only)
          raise NotImplementedError, "#{self.class.name} does not implement actors"
        end

        def movies
          raise NotImplementedError, "#{self.class.name} does not implement movies"
        end
      end
    end
  end
end
