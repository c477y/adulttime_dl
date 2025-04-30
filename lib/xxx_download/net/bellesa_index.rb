# frozen_string_literal: true

module XXXDownload
  module Net
    class BellesaIndex < BaseIndex
      TAG = "BELLESA_INDEX"
      BASE_URI = "FILL_ME_IN"
      base_uri BASE_URI

      # Delete methods that your site does not support

      # @param [String] url
      # @return [Array<Data::Scene>]
      def search_by_all_scenes(url)
        raise NotImplementedError, "#{self.class.name} does not implement search_by_all_scenes to handle #{url}"
      end

      # @param [String] url
      # @return [Array<Data::Scene>]
      def search_by_movie(url)
        raise NotImplementedError, "#{self.class.name} does not implement search_by_movie to handle #{url}"
      end

      # @param [String] url
      # @return [Array<Data::Scene>]
      def search_by_actor(url)
        raise NotImplementedError, "#{self.class.name} does not implement search_by_actor to handle #{url}"
      end

      # @param [String] url
      # @return [Array<Data::Scene>]
      def search_by_page(url)
        raise NotImplementedError, "#{self.class.name} does not implement search_by_page to handle #{url}"
      end

      # @param [String] resource
      # @return [String]
      def actor_name(resource)
        raise NotImplementedError, "#{self.class.name} does not implement actor_name to handle #{resource}"
      end
    end
  end
end
