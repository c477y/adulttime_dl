# frozen_string_literal: true

module AdultTimeDL
  module Processor
    class MovieProcessor < BaseProcessor
      def scenes
        index.search_by_movie(entity_id, entity_name, url: url)
      end
    end
  end
end
