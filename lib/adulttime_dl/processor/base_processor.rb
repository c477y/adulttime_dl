# frozen_string_literal: true

module AdultTimeDL
  module Processor
    class BaseProcessor
      attr_reader :index, :url

      # @param [Net::AlgoliaClient] index
      # @param [String] url
      def initialize(index, url)
        @index = index
        @url = url
      end

      private

      def entity_name
        path.split("/")&.[](-2)&.gsub("-", " ")
      end

      def entity_id
        path.split("/")&.last
      end

      def path
        uri.path
      end

      def uri
        @uri ||= URI(url)
      end
    end
  end
end

