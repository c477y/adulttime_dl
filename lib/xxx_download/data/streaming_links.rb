# frozen_string_literal: true

module XXXDownload
  module Data
    class StreamingLinks < Base
      attribute? :res_2160p, Types::String
      attribute? :res_4k, Types::String
      attribute? :res_1080p, Types::String
      attribute? :res_720p, Types::String
      attribute? :res_576p, Types::String
      attribute? :res_480p, Types::String
      attribute? :res_432p, Types::String
      attribute? :res_360p, Types::String
      attribute? :res_270p, Types::String
      attribute? :default, Types::Array.of(Types::String).default([].freeze)

      def self.with_single_url(url)
        hash = {}
        hash["default"] = [url]
        new(hash)
      end

      def sd
        res_480p || res_432p || res_360p || default.first || nil
      end

      def hd
        res_720p || res_576p || sd
      end

      def fhd
        res_1080p || hd
      end
    end
  end
end
