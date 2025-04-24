# frozen_string_literal: true

module XXXDownload
  module Data
    class Scene < Base
      RESOLUTION_MAP = {
        "sd" => %w[480p 360p 240p 160p],
        "hd" => %w[720p 576p],
        "fhd" => %w[1080p],
        "4k" => %w[2160p]
      }.freeze

      LAZY = {
        lazy: true,
        title: "__LAZY__",
        network_name: "__LAZY__",
        collection_tag: "__LAZY__"
      }.freeze

      FAIL = {
        lazy: false,
        title: "__FAIL__",
        network_name: "__FAIL__",
        collection_tag: "__FAIL__",
        downloading_links: {}
      }.freeze

      NOT_LAZY = { lazy: false }.freeze

      def initialize(attributes)
        if attributes[:lazy] && attributes[:refresher].nil?
          raise XXXDownload::FatalError, "Lazy evaluated scenes must have a refresher"
        end

        super(attributes)
      end

      def self.fail_scene(video_link) = new(video_link:, **FAIL)

      # Scenes can be resolved lazily. This can be useful if download/streaming links have an expiry
      # In such cases, you can explicitly mark a scene as lazy and pass in two mandatory attributes:
      # - video_link: the URL to the scene
      # - refresher: a class that can refresh the scene data. This class must implement a `refresh` method
      attribute :lazy, Types::Bool
      attribute :video_link, Types::String
      attribute? :refresher, Types.Instance(Net::Refreshers::BaseRefresh)

      attribute? :clip_id, Types::Integer
      attribute :title, Types::String
      attribute :actors, Types::Array.of(Actor).default([].freeze)
      attribute :network_name, Types::String
      attribute :collection_tag, Types::String.default("C")

      attribute? :tags, Types::CustomSet
      attribute? :duration, Types::String
      attribute? :release_date, Types::String
      attribute? :movie_title, Types::String
      attribute? :download_sizes, Types::Array.of(Types::String)
      attribute? :streaming_links, StreamingLinks
      attribute? :downloading_links, StreamingLinks

      alias lazy? lazy

      def key
        clip_id.nil? ? title : clip_id.to_s
      end

      # @param [Data::StreamingLinks] links
      # @return [Scene]
      def add_streaming_links(links)
        new(streaming_links: links)
        # Scene.new(to_hash.merge(streaming_links: links))
      end

      def refresh(**opts)
        return self if refresher.nil?

        refresher.refresh(**opts)
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

      def all_actors(sorted = true)
        a = actors.map(&:name)
        return a unless sorted

        a.sort
      end

      def gender_unknown_actors?
        actors.any? { |x| x.gender == "unknown" }
      end

      def lesbian?
        female_actors.present? && male_actors.blank? && !gender_unknown_actors?
      end

      def trans?
        actors.any? { |x| x.gender == "shemale" }
      end

      #
      # Generate a file name for the scene
      #
      # @return [String]
      def file_name
        initial_name = []
        initial_name << "#{release_date} [T]" if release_date.present?
        initial_name << title
        initial_name << "[#{collection_tag}]"
        initial_name << (movie_title.present? ? movie_title : network_name)
        actor_tag_len = 4 # length of [F] or [M] or [A]

        if gender_unknown_actors?
          initial_name << "[A]"
          actor_s = safe_actor_string(all_actors, MAX_FILENAME_LEN - initial_name.join(" ").length - actor_tag_len)
          initial_name << actor_s
        else
          female_actor_s = safe_actor_string(female_actors,
                                             MAX_FILENAME_LEN - initial_name.join(" ").length - actor_tag_len)
          initial_name << "[F] #{female_actor_s}" unless female_actor_s.empty?
          male_actor_s = safe_actor_string(male_actors,
                                           MAX_FILENAME_LEN - initial_name.join(" ").length - actor_tag_len)
          initial_name << "[M] #{male_actor_s}" unless male_actor_s.empty?
        end
        initial_name = initial_name.join(" ")
        clean(initial_name)
      end

      def fail? = title == "__FAIL__"

      private

      # Some file systems don't play nice with long file names
      MAX_FILENAME_LEN = 240

      # @param [Array[String]] actors
      # @param [Integer] max_allowed_len
      def safe_actor_string(actors, max_allowed_len)
        return "" if actors.empty?

        name = actors.join(", ")
        XXXDownload.logger.error "MAX(#{max_allowed_len}), LEN(#{name.length}) CURRENT NAME #{name}"
        return name if name.length < max_allowed_len

        safe_actor_string(actors[0...-1], max_allowed_len)
      end

      def clean(str)
        str
          .gsub(/[^\s\w\[\].,\-_]+/i, "") # remove non-alphanumeric characters
          .gsub(/\s{2,}/, " ").strip # remove extra spaces
      end
    end
  end
end
