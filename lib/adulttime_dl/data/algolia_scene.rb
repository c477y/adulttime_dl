# frozen_string_literal: true

module AdultTimeDL
  module Data
    class AlgoliaScene < Base
      attribute :clip_id, Types::Integer
      attribute :title, Types::String
      attribute :actors, Types::Array.of(AlgoliaActor)
      attribute :release_date, Types::String
      attribute :network_name, Types::String.default("AdultTime")
      attribute :downloaded?, Types::Bool.default(false)
      attribute? :streaming_links, StreamingLinks
      attribute :is_downloaded, Types::Bool.default(false)

      def key
        clip_id.to_s
      end

      # @return [AlgoliaScene]
      def mark_downloaded(value)
        AlgoliaScene.new(to_hash.merge(is_downloaded: value))
      end

      # @return [AlgoliaScene]
      def add_streaming_links(links)
        AlgoliaScene.new(to_hash.merge(streaming_links: links))
      end

      def female_actors
        actors.select { |x| x.gender == "female" }.map(&:name).sort
      end

      def male_actors
        actors.select { |x| x.gender == "male" }.map(&:name).sort
      end

      def lesbian?
        male_actors.empty?
      end

      def downloaded?
        is_downloaded
      end

      def file_name
        name = "#{title} [C] #{network_name} [F] #{female_actors.join(", ")}"
        name += " [M] #{male_actors.join(", ")}" if male_actors.length.positive?
        name.gsub(/[^\s\w\[\].,\-_]+/i, "").gsub(/\s{2,}/, " ")
      end
    end
  end
end
