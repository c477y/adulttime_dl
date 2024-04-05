# frozen_string_literal: true

module XXXDownload
  module Net
    module Generators
      class BaseGenerator < Base
        attr_reader :config

        # @param [XXXDownload::Data::GeneratorConfig] config
        def initialize(config)
          super()
          @config = config
          self.class.follow_redirects false
        end

        def actors
          raise NotImplementedError, "#{self.class.name} does not implement actors"
        end

        def movies
          raise NotImplementedError, "#{self.class.name} does not implement movies"
        end

        private

        def fetch(url)
          resp = handle_response!(return_raw: true) { self.class.get(url) }
          Nokogiri::HTML(resp.body)
        end
      end
    end
  end
end
