# frozen_string_literal: true

module AdultTimeDL
  module Net
    class AdultTimeIndex < AlgoliaClient
      INDEX_NAME = "all_scenes_latest_desc"

      private

      def index
        @index ||= client.init_index(INDEX_NAME)
      end
    end
  end
end
