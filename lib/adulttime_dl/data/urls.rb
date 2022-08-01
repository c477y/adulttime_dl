# frozen_string_literal: true

module AdultTimeDL
  module Data
    class URLs < Base
      attribute :all_scenes, Types::Array.of(Types::String).default([].freeze)
      attribute :performers, Types::Array.of(Types::String).default([].freeze)
      attribute :movies, Types::Array.of(Types::String).default([].freeze)
      attribute :scenes, Types::Array.of(Types::String).default([].freeze)
    end
  end
end
