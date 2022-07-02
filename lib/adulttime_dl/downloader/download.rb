# frozen_string_literal: true

module AdultTimeDL
  module Downloader
    class Download
      extend Forwardable

      def_delegators :@config, :download_dir, :store, :performer_file, :parallel, :quality,
                     :verbose, :skip_studios, :blacklisted_studios

      # @param [Data::DownloadStatusDatabase] store
      # @param [Data::Config] config
      def initialize(store:, config:)
        @config = config
        @client = config.downloader
        @store = store
      end

      # @param [Data::AlgoliaScene] scene_data
      def download(scene_data, link_fetcher)
        if store.downloaded?(scene_data.key)
          AdultTimeDL.logger.info "[ALREADY DOWNLOADED] #{scene_data.file_name}"
          nil
        elsif blacklisted_studios.member?(scene_data.network_name.downcase.gsub(/\W+/i, ""))
          AdultTimeDL.logger.info "[SKIPPING NETWORK #{scene_data.network_name}] #{scene_data.file_name}"
          nil
        elsif scene_data.lesbian? && config
          AdultTimeDL.logger.info "[SKIPPING LESBIAN SCENE] #{scene_data.file_name}"
          nil
        elsif (streaming_links = link_fetcher.fetch(scene_data.clip_id))
          new_scene_data = scene_data.add_streaming_links(streaming_links)
          start_download(new_scene_data)
        else
          AdultTimeDL.logger.error "[NO DOWNLOAD LINK] #{scene_data.file_name}"
          nil
        end
      end

      private

      attr_reader :client, :store, :config

      # @param [Data::AlgoliaScene] scene_data
      def start_download(scene_data)
        command = generate_command(scene_data)
        Open3.popen2e(command) do |_, stdout_and_stderr, thread|
          output = []
          AdultTimeDL.logger.info "[PID] #{thread.pid} [FILE] #{scene_data.file_name}"
          stdout_and_stderr.each do |line|
            output << line
            AdultTimeDL.file_logger.info("#{thread.pid} -- #{line}")
          end

          exit_status = thread.value
          if exit_status != 0
            store.save_download(scene_data, is_downloaded: false)
            AdultTimeDL.logger.error "[DOWNLOAD_FAIL] #{scene_data.file_name} -- #{output[-1].strip}"
          else
            store.save_download(scene_data, is_downloaded: true)
            AdultTimeDL.logger.info "[DOWNLOAD_COMPLETE] #{scene_data.file_name}"
          end
        end
      end

      # @param [Data::AlgoliaScene] scene_data
      # @return [String]
      def generate_command(scene_data)
        CommandBuilder.new
                      .with_download_client(client)
                      .with_merge_parts(true)
                      .with_path(scene_data.file_name, download_dir)
                      .with_url(scene_data.streaming_links.send(quality.to_sym))
                      .build
      end
    end
  end
end
