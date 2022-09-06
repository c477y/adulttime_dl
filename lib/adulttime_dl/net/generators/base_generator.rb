# frozen_string_literal: true

module AdultTimeDL
  module Net
    module Generators
      class BaseGenerator < Base

        attr_reader :config

        def initialize(config)
          @config = config
          super()
        end

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

