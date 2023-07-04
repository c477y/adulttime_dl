# frozen_string_literal: true

module AdultTimeDL
  module Data
    class Scene < Base
      RESOLUTION_MAP = {
        "sd" => %w[480p 360p 240p 160p],
        "hd" => %w[720p 576p],
        "fhd" => %w[1080p]
      }.freeze

      attribute :clip_id, Types::Integer.default(-1)
      attribute :title, Types::String
      attribute :actors, Types::Array.of(Actor).default([].freeze)
      attribute? :release_date, Types::String.optional
      attribute :network_name, Types::String.optional
      attribute? :movie_title, Types::String
      attribute? :download_sizes, Types::Array.of(Types::String)
      attribute? :streaming_links, StreamingLinks
      attribute? :downloading_links, StreamingLinks
      attribute :collection_tag, Types::String.default("C")
      attribute :is_downloaded, Types::Bool.default(false)
      attribute :is_streamable, Types::Bool.default(true)
      attribute? :video_link, Types::String
      attribute? :refresher, Types.Instance(Class)

      def key
        clip_id == -1 ? title : clip_id.to_s
      end

      # @param [Boolean] value
      # @return [Scene]
      def mark_downloaded(value)
        new(is_downloaded: value)
        # Scene.new(to_hash.merge(is_downloaded: value))
      end

      # @param [Data::StreamingLinks] links
      # @return [Scene]
      def add_streaming_links(links)
        new(streaming_links: links)
        # Scene.new(to_hash.merge(streaming_links: links))
      end

      # @return [Scene]
      def non_streamable
        new(is_streamable: false)
        # Scene.new(to_hash.merge(is_streamable: false))
      end

      def refresh_required?
        title == "PLACEHOLDER"
      end

      def refresh(cookie)
        refresher.nil? ? self : refresher.new(video_link, cookie).process
      end

      # @param [String] quality: one of "sd", "hd" or "fhd"
      # @return [String] matching resolution from scene's available download_sizes
      def available_resolution(quality)
        resolutions = RESOLUTION_MAP[quality]
        resolutions.each do |resolution|
          return resolution if download_sizes.include?(resolution)
        end
        download_sizes.last || ""
      end

      def female_actors
        actors.select { |x| x.gender == "female" }.map(&:name).sort
      end

      def male_actors
        actors.select { |x| x.gender == "male" }.map(&:name).sort
      end

      def all_actors
        actors.map(&:name).sort
      end

      def actor_gender_unknown?
        actors.select { |x| x.gender == "unknown" }.any?
      end

      def lesbian?
        male_actors.empty?
      end

      def downloaded?
        is_downloaded
      end

      def non_streamable?
        !is_streamable
      end

      def file_name
        initial_name = "#{title} [#{collection_tag}] #{network_name}"
        if actor_gender_unknown?
          final = safely_add_actors(initial_name, all_actors, prefix: "[A]")
        else
          with_female = safely_add_actors(initial_name, female_actors, prefix: "[F]")
          final = safely_add_actors(with_female, male_actors, prefix: "[M]")
        end
        clean(final)
      end

      private

      def safely_add_actors(fixed_str, actors, max_len = 150, prefix:)
        return fixed_str if actors.length.zero?

        name = "#{fixed_str} #{prefix} #{actors.join(", ")}"
        return name if name.length < max_len

        safely_add_actors(fixed_str, actors[0...-1], prefix: prefix)
      end

      def clean(str)
        str.gsub(/[^\s\w\[\].,\-_]+/i, "").gsub(/\s{2,}/, " ").strip
      end
    end
  end
end
