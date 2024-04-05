# frozen_string_literal: true

module XXXDownload
  module Data
    class URLs < Base
      attribute :performers, Types::Array.of(Types::String).default([].freeze)
      attribute :movies, Types::Array.of(Types::String).default([].freeze)
      attribute :scenes, Types::Array.of(Types::String).default([].freeze)
      attribute :page, Types::Array.of(Types::String).default([].freeze)
    end
  end
end
