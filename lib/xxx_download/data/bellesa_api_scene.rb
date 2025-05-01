# frozen_string_literal: true

module XXXDownload
  module Data
    class BellesaApiScene < Base
      class NoSourceError < StandardError; end

      RESOLUTIONS = [360, 480, 720, 1080, 1440, 2160].to_set.freeze
      DOWNLOAD_URL = "https://s.bellesa.co/v/%<source>s/%<resolution>s.mp4"

      attribute :id, Types::Integer
      attribute :posted_on, Types::Integer
      attribute :title, Types::String

      # modified attribute: API response returns a string of comma-separated tags
      attribute :tags, Types::CustomSet
      attribute? :source, Types::String

      # modified attribute: API response returns a string of comma-separated resolutions
      attribute :resolutions, Types::CustomSet
      attribute :duration, Types::Integer # HH:MM
      attribute :content_provider, Types::Array.of(
        Types::Hash.schema(
          name: Types::String
        )
      )
      attribute :performers, Types::Array.of(
        Types::Hash.schema(
          name: Types::String
        )
      )

      def initialize(attributes)
        super(attributes)
        validate!
      end

      # @return [Data::Scene]
      # noinspection RubyMismatchedReturnType
      def to_scene
        Scene.new(
          {
            video_link:,
            title:,
            actors:,
            network_name:,
            tags: tags.to_a,
            duration: formatted_scene_duration,
            release_date:,
            download_sizes: resolutions.to_a,
            downloading_links:
          }.merge(Scene::NOT_LAZY)
        )
      end

      private

      def actors                   = performers.map { |x| Actor.unknown(x[:name]) }
      def network_name             = content_provider.first&.fetch(:name, "Bellesa")
      def collection_tag           = "BEL"
      def formatted_scene_duration = format("%<hours>02d:%<minutes>02d", hours: duration / 60, minutes: duration % 60)
      def release_date             = Time.at(posted_on).strftime("%Y-%m-%d")

      def video_link
        stub = title.downcase.gsub(/\W/, " ").gsub(/\s{2,}/, " ").gsub(" ", "-")
        "https://bellesaplus.co/videos/#{id}/#{stub}"
      end

      def downloading_links
        links = {}
        default = []
        resolutions.each do |resolution|
          link = format(DOWNLOAD_URL, source:, resolution:)
          default.push(link)
          links["res_#{resolution}p"] = link
        end
        links["default"] = default
        links
      end

      def validate!
        raise NoSourceError unless source.present?

        unhandled_resolutions = resolutions - RESOLUTIONS
        return unless unhandled_resolutions.any?

        msg = "Scene #{title} has unhandled resolutions: #{unhandled_resolutions.join(", ")}"
        XXXDownload.logger.debug(msg)
      end
    end
  end
end
