# frozen_string_literal: true

module XXXDownload
  module Net
    class YppApiProcessor
      include XXXDownload::Utils

      # @param [String] tour_base_url A URL to the non-member page
      # @param [String] network Network name (site powered by YPP)
      # @param [String] collection_tag A upto 3 character tag for the network
      # @param [Data::Actor, NilClass] default_actor The default actor name to add to the scene
      #   This is useful for sites that are owned by a single actor, so their name(s) are not
      #   returned in the API response
      def initialize(tour_base_url, network, collection_tag, default_actor)
        @tour_base_url = tour_base_url
        @network = network
        @collection_tag = collection_tag
        @default_actor = default_actor
      end

      def make_scene_data(scene)
        log_scene(scene)
        scene_hash = {}.tap do |h|
          h[:lazy] = false
          h[:video_link] = File.join(tour_base_url, "scenes", scene["slug"])
          h[:title] = scene["title"]

          h[:actors] = actors(scene)
          h[:network_name] = network
          h[:collection_tag] = collection_tag
          h[:tags] = scene["tags"]
          h[:duration] = scene["videos_duration"]
          parsed_time = parse_time(scene["publish_date"], "%Y/%m/%d %H:%M:%S")
          h[:release_date] = parsed_time if parsed_time.present?
          h[:download_sizes] = download_sizes(scene["videos"])
          h[:is_streamable] = false
          h[:downloading_links] = download_links(scene["videos"])
        end
        Data::Scene.new(scene_hash)
      end

      private

      attr_reader :tour_base_url, :network, :collection_tag, :default_actor

      TAG = "YPP_API_PROCESSOR"

      def actors(scene)
        if default_actor.present?
          actors = scene["models"].map { |x| Data::Actor.new(name: x, gender: "female") }
          actors << default_actor
        else
          scene["models"].map { |x| Data::Actor.new(name: x, gender: "unknown") }
        end
      end

      # @param [Hash] videos
      # @return [Array[String]]
      def download_sizes(videos)
        sizes = []
        videos.each_pair do |stream_res, value|
          XXXDownload.logger.extra "[#{TAG}] Found video \"#{stream_res}\" of " \
                                   "height: #{value["height"]} and width #{value["width"]}"
          sizes << case value["height"]
                   when 2160
                     "4k"
                   when 1080
                     "fhd"
                   when 720, 540
                     "hd"
                   when 480, 360, 270
                     "sd"
                   else
                     XXXDownload.logger.warn "[#{TAG}] No resolution matched for " \
                                             "video res #{value["height"]}x#{value["width"]}"
                     nil
                   end
        end
        sizes.compact
      end

      # @param [Hash] videos
      # @return [Data::StreamingLinks]
      def download_links(videos)
        res = { "default" => [] }
        videos.each_pair do |stream_res, value|
          XXXDownload.logger.extra "[#{TAG}] Found video \"#{stream_res}\" of download link #{value["download"]}"
          key = "res_#{value["height"]}p"
          res[key] = value["download"]
          res["default"] << value["download"]
        end

        # noinspection RubyMismatchedReturnType
        Data::StreamingLinks.new(res)
      end

      def log_scene(scene)
        XXXDownload.logger.trace "[#{TAG}] Parsing scene: #{scene["title"]}"
        subset = scene.slice("title", "slug", "models", "tags", "videos_duration", "publish_date", "videos")
        XXXDownload.logger.ap subset, :extra
      end
    end
  end
end
