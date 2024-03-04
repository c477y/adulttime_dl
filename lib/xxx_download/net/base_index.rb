# frozen_string_literal: true

module XXXDownload
  module Net
    class BaseIndex < Base

      def search_by_all_scenes(_url)
        raise NotImplementedError, "#{self.class.name} does not implement search_by_all_scenes"
      end

      def search_by_movie(_url)
        raise NotImplementedError, "#{self.class.name} does not implement search_by_movie"
      end

      def search_by_actor(_url)
        raise NotImplementedError, "#{self.class.name} does not implement search_by_actor"
      end

      def actor_name(_url)
        raise NotImplementedError, "#{self.class.name} does not implement actor_name"
      end

      #
      # This is a default implementation to generate a download command
      # Override this and add a custom implementation if required.
      # e.g. for sites that use HLS streaming will require a custom command
      # @param [XXXDownload::Data::Scene] scene_data
      # @return [String] a command to run in shell to download a scene
      def command(scene_data, url)
        XXXDownload::Downloader::CommandBuilder.build_basic do |b|
          b.path(scene_data.file_name, config.download_dir)
          b.url(url)
        end
      end

      private

      attr_reader :config

      def placeholder_scene_hash
        {
          title: "PLACEHOLDER",
          actors: [],
          network_name: "PLACEHOLDER"
        }
      end
    end
  end
end
