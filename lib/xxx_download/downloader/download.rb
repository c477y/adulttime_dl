# frozen_string_literal: true

require "open3"

module XXXDownload
  module Downloader
    class Download
      include XXXDownload::Utils

      # @param [Data::DownloadStatusDatabase] store
      def initialize(store:, semaphore:)
        @store = store
        @semaphore = semaphore
      end

      #
      # Download a file using scene_data
      #
      # @param [Data::Scene] scene_data
      # @param [Proc] proc A block that accepts `scene_data` and `url`
      #   and returns a `command` string
      def download(scene_data, proc)
        @command_generator = proc
        scene_data = scene_data.refresh if scene_data.lazy?

        return if already_downloaded?(scene_data)

        return if config.skip_scene?(scene_data)

        # Try to download file using direct download
        # If that fails, try to stream the video and download the HLS stream
        download_using_video_url(scene_data) || download_using_stream(scene_data)
      end

      private

      attr_reader :store, :semaphore, :command_generator

      delegate :streaming_link_fetcher, :download_link_fetcher, to: :config

      #
      # Check if the file has already been downloaded
      # Looks in the local datastore file and in Stash app (if configured)
      #
      # @param [XXXDownload::Data::Scene] scene_data
      # @return [Boolean]
      def already_downloaded?(scene_data)
        if store.downloaded?(scene_data.key)
          XXXDownload.logger.info "[ALREADY DOWNLOADED] #{scene_data.file_name}"
          return true
        elsif (scene = stash_app&.scene(scene_data))
          store.save_download(scene_data)
          XXXDownload.logger.info "[STASH: FILE EXISTS] #{scene_data.title}"
          XXXDownload.logger.debug "TITLE: #{scene["title"]}"
          XXXDownload.logger.debug "PATH: #{scene["files"]&.first&.[]("path")}"
          return true
        end
        false
      end

      def stash_app
        return @stash_app if defined?(@stash_app)

        @stash_app ||=
          begin
            return nil if config.stash_app&.url.nil?

            app = Net::StashApp.new(config)
            app.setup_credentials!
            app
          end
      end

      # @param [Data::Scene] scene_data
      def download_using_video_url(scene_data)
        url = download_link_fetcher.fetch(scene_data)
        return false if url.nil?

        command = command_generator.call(scene_data, url)
        if config.dry_run?
          XXXDownload.logger.info "WILL DOWNLOAD #{command}"
        else
          start_download(scene_data, command)
        end
      rescue APIError => e
        XXXDownload.logger.error("[DIRECT DOWNLOAD FAIL] #{e.message}")
        false
      end

      # @param [Data::Scene] scene_data
      def download_using_stream(scene_data)
        streaming_links = streaming_link_fetcher.fetch(scene_data)
        return false if streaming_links.nil?

        scene_data = scene_data.add_streaming_links(streaming_links)
        url = scene_data.streaming_links.send(config.quality.to_sym)
        command = command_generator.call(scene_data, url)
        if config.dry_run?
          XXXDownload.logger.info "WILL DOWNLOAD #{command}"
        else
          start_download(scene_data, command)
        end
      rescue APIError => e
        XXXDownload.logger.error("[DIRECT DOWNLOAD FAIL] #{e.message}")
        if e.is_a?(XXXDownload::RedirectedError)
          raise FatalError, "Redirection suggests possible cookie/token expiry. Regenerate token and try again."
        end
      end

      # @param [Data::Scene] scene_data
      # @return [Boolean]
      def start_download(scene_data, command)
        XXXDownload.logger.debug command
        Open3.popen2e(command) do |_, stdout_and_stderr, thread|
          output = ""
          XXXDownload.logger.info "[PID] #{thread.pid} [FILE] #{scene_data.file_name.to_s.colorize(:green)}"
          stdout_and_stderr.each do |line|
            output = line
            XXXDownload.file_logger.info("#{thread.pid} -- #{line}")
          end

          exit_status = thread.value
          if exit_status != 0
            store.save_download(scene_data)
            XXXDownload.logger.error "[DOWNLOAD_FAIL] #{scene_data.file_name} -- #{output.strip}"
            return false
          else
            valid_file_size?(scene_data)
            store.save_download(scene_data)
            XXXDownload.logger.info "[DOWNLOAD_COMPLETE] #{scene_data.file_name}"
            return true
          end
        end
        false
      end

      def valid_file_size?(scene_data)
        # replace all non-word characters with `?` for globbing to work
        search_str = "#{scene_data.file_name.gsub(/[^-\w\s]/, "?")}.*"
        matching_file = Dir[search_str].first
        if matching_file.nil?
          XXXDownload.logger.warn "[FILENAME RESOLUTION FAILURE] #{File.join(Dir.pwd, filename)}"
        elsif File.size?(matching_file) < 20_000
          size = File.size(filename)
          ::FileUtils.remove_file(filename)
          raise FileSizeTooSmallError.new(filename, size)
        end
      rescue FileSizeTooSmallError => e
        XXXDownload.logger.warn e.message
        false
      end

      def client
        config.downloader
      end

      def config
        XXXDownload.config
      end
    end
  end
end
