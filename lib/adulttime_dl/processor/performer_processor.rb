# frozen_string_literal: true

module AdultTimeDL
  module Processor
    class PerformerProcessor < BaseProcessor
      def scenes
        index.search_by_actor(entity_id, entity_name, url: url)
      end
    end
  end
end
