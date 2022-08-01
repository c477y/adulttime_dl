# frozen_string_literal: true

module AdultTimeDL
  module Downloader
    class Download
      extend Forwardable

      # @param [Data::DownloadStatusDatabase] store
      # @param [Data::Config] config
      def initialize(store:, config:, semaphore:)
        @config = config
        @client = config.downloader
        @store = store
        @semaphore = semaphore
      end

      #
      # Download a file using scene_data
      #
      # @param [Data::Scene] scene_data
      # @return [FalseClass, TrueClass]
      def download(scene_data)
        if store.downloaded?(scene_data.key) || file_exists?(scene_data)
          AdultTimeDL.logger.info "[ALREADY DOWNLOADED] #{scene_data.file_name}"
          return
        end

        return if config.skip_scene?(scene_data)

        download_using_video_url(scene_data) || download_using_stream(scene_data)
      end

      private

      attr_reader :client, :store, :config, :semaphore

      def_delegators :@config, :streaming_link_fetcher, :download_link_fetcher

      def refresh_data(scene_data)
        store.save_download(scene_data, is_downloaded: store.downloaded?(scene_data.key))
      end

      def file_exists?(scene_data)
        complete_fn = "#{scene_data.file_name}.mp4"
        if File.file?(complete_fn) && File.exist?(complete_fn)
          store.save_download(scene_data, is_downloaded: true)
          return true
        end
        false
      end

      # @param [Data::Scene] scene_data
      def download_using_video_url(scene_data)
        url = download_link_fetcher.fetch(scene_data)
        return false if url.nil?

        command = generate_command(scene_data, url)
        AdultTimeDL.logger.debug("[ATTEMPT DOWNLOAD USING FILE URL] #{scene_data.file_name}")
        start_download(scene_data, command)
      rescue APIError => e
        AdultTimeDL.logger.error("[DIRECT DOWNLOAD FAIL] #{e.message}")
        false
      end

      # @param [Data::Scene] scene_data
      def download_using_stream(scene_data)
        streaming_links = streaming_link_fetcher.fetch(scene_data)
        return false if streaming_links.nil?

        scene_data = scene_data.add_streaming_links(streaming_links)
        url = scene_data.streaming_links.send(config.quality.to_sym)
        command = generate_command(scene_data, url)
        AdultTimeDL.logger.debug("[ATTEMPT DOWNLOAD USING STREAMING URL] #{scene_data.file_name}")
        start_download(scene_data, command)
      rescue APIError => e
        AdultTimeDL.logger.error("[DIRECT DOWNLOAD FAIL] #{e.message}")
      end

      # @param [Data::Scene] scene_data
      # @return [TrueClass, FalseClass]
      def start_download(scene_data, command)
        AdultTimeDL.logger.debug command
        Open3.popen2e(command) do |_, stdout_and_stderr, thread|
          output = ""
          AdultTimeDL.logger.info "[PID] #{thread.pid} [FILE] #{scene_data.file_name}"
          stdout_and_stderr.each do |line|
            output = line
            AdultTimeDL.file_logger.info("#{thread.pid} -- #{line}")
          end

          exit_status = thread.value
          if exit_status != 0
            store.save_download(scene_data, is_downloaded: false)
            AdultTimeDL.logger.error "[DOWNLOAD_FAIL] #{scene_data.file_name} -- #{output}"
            false
          else
            valid_file_size!(scene_data)
            store.save_download(scene_data, is_downloaded: true)
            AdultTimeDL.logger.info "[DOWNLOAD_COMPLETE] #{scene_data.file_name}"
            true
          end
        end
      rescue FileSizeTooSmallError => e
        AdultTimeDL.logger.warn e.message
        false
      end

      # @param [Data::Scene] scene_data
      # @param [String] url
      # @return [String]
      def generate_command(scene_data, url)
        CommandBuilder.new
                      .with_download_client(client)
                      .with_merge_parts(true)
                      .with_path(scene_data.file_name, config.download_dir)
                      .with_quality(!scene_data.streaming_links.default.nil?, "720")
                      .with_verbosity(config.verbose)
                      .with_cookie(config.cookie_file, config.downloader_requires_cookie?)
                      .with_url(url).build
        # .with_quality(!scene_data.streaming_links.default.nil?, "720")
      end

      # @param [Data::Scene] scene_data
      def valid_file_size!(scene_data)
        semaphore.synchronize { unsafe_valid_file_size!(scene_data) }
      end

      #
      # This method is not thread safe and will raise a runtime error if
      # called by multiple threads at once
      #
      # @param [Data::Scene] scene_data
      def unsafe_valid_file_size!(scene_data)
        Dir.chdir(config.download_dir) do
          filename = "#{scene_data.file_name}.mp4"
          if File.file?(filename) && File.exist?(filename) && File.size?(filename) < 5000
            size = File.size(filename)
            ::FileUtils.remove_file(filename)
            raise FileSizeTooSmallError.new(filename, size)
          end
          true
          #
          # TODO: Check why this doesn't work
          #
          # matching_files = Dir["#{scene_data.file_name}.*"]
          # filename = matching_files.first
          #
          # if matching_files.length > 1
          #   AdultTimeDL.logger.warn "[EXPECTED SINGLE MATCH #{scene_data.file_name}] #{matching_files}"
          #   return
          # end
          #
          # return if filename.nil?
          #
          # if File.file?(filename) && File.exist?(filename) && File.size?(filename) < 5000
          #   size = File.size(filename)
          #   ::FileUtils.remove_file(filename)
          #   raise FileSizeTooSmallError.new(filename, size)
          # end
          #
          # true
        end
      end

      def valid_file_size?(scene_data)
        valid_file_size!(scene_data)
      rescue FileSizeTooSmallError => e
        AdultTimeDL.logger.warn e.message
        false
      end
    end
  end
end
