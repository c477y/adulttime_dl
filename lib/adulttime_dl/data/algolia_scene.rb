# frozen_string_literal: true

module AdultTimeDL
  module Data
    class AlgoliaScene < Base
      attribute :clip_id, Types::Integer
      attribute :title, Types::String
      attribute :actors, Types::Array.of(AlgoliaActor)
      attribute :release_date, Types::String
      attribute :network_name, Types::String.optional
      # attribute :streaming_links, StreamingLinks.optional
    end
  end
end
