# frozen_string_literal: true

module AdultTimeDL
  module Net
    class BaseIndex < Base
      def initialize(config)
        @config = config
        super()
      end

      def search_by_all_scenes(_url)
        raise NotImplementedError, "#{self.class.name} does not implement search_by_all_scenes"
      end

      def search_by_movie(_url)
        raise NotImplementedError, "#{self.class.name} does not implement search_by_movie"
      end

      def search_by_actor(_url)
        raise NotImplementedError, "#{self.class.name} does not implement search_by_actor"
      end

      def actor_name(_url)
        raise NotImplementedError, "#{self.class.name} does not implement actor_name"
      end

      private

      attr_reader :config

      def placeholder_scene_hash
        {
          title: "PLACEHOLDER",
          actors: [],
          network_name: "PLACEHOLDER"
        }
      end
    end
  end
end
