# frozen_string_literal: true

module AdultTimeDL
  module Processor
    class PerformerProcessor
      attr_reader :scene_index, :url

      # @param [Net::ScenesIndex] scene_index
      # @param [String] url
      def initialize(scene_index, url)
        @scene_index = scene_index
        @url = url
      end

      def scenes
        scene_index.search_by_actor_name(actor_name)
      end

      private

      def actor_name
        path.split("/")&.[](-2)&.gsub("-", " ")
      end

      def actor_id
        path.split("/")&.last
      end

      def path
        uri.path
      end

      def valid_link?
        uri.path&.include?("/pornstar/view")
      end

      def uri
        @uri ||= URI(url)
      end
    end
  end
end
