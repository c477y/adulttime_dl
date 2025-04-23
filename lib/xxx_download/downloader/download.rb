# frozen_string_literal: true

require "open3"

module XXXDownload
  module Downloader
    class Download
      include XXXDownload::Utils

      TAG = "DOWNLOADER"

      # @param [Data::DownloadStatusDatabase] store
      def initialize(store:, semaphore:)
        @store = store
        @semaphore = semaphore
      end

      #
      # Download a file using scene_data
      #
      # @param [Data::Scene] scene_data
      # @param [XXXDownload::Net::BaseIndex] scenes_index
      def download(scene_data, scenes_index)
        @scenes_index = scenes_index

        scene_data = scene_data.refresh(web_driver:) if scene_data.lazy?

        return false if already_downloaded?(scene_data)

        return false if config.skip_scene?(scene_data)

        # Try to download file using direct download
        # If that fails, try to stream the video and download the HLS stream
        download_using_video_url(scene_data) || download_using_stream(scene_data)
      end

      private

      attr_reader :store, :semaphore, :scenes_index

      delegate :streaming_link_fetcher, :download_link_fetcher, to: :config

      def web_driver
        scenes_index.respond_to?(:default_options) ? scenes_index.default_options : nil
      end

      #
      # Check if the file has already been downloaded
      # Looks in the local datastore file and in Stash app (if configured)
      #
      # @param [XXXDownload::Data::Scene] scene_data
      # @return [Boolean]
      def already_downloaded?(scene_data)
        if store.downloaded?(scene_data.key)
          XXXDownload.logger.info "[#{TAG}: ALREADY DOWNLOADED] #{scene_data.file_name}"
          return true
        elsif (scene = stash_app&.scene(scene_data))
          store.save_download(scene_data)
          XXXDownload.logger.info "[#{TAG}: FILE EXISTS IN STASH] #{scene_data.title}"
          XXXDownload.logger.debug "\tPATH: #{scene["files"]&.first&.[]("path")}"
          return true
        elsif (file = file_downloaded?(scene_data))
          XXXDownload.logger.info "[#{TAG}: FILE EXISTS] #{file}"
          return true
        end

        false
      end

      def stash_app
        return @stash_app if defined?(@stash_app)

        @stash_app ||=
          if config.stash_app.url.present?
            app = Net::StashApp.new(config)
            app.setup_credentials!
            app
          end
      end

      # @param [Data::Scene] scene_data
      def download_using_video_url(scene_data)
        XXXDownload.logger.trace "[#{TAG}] ATTEMPT DIRECT DOWNLOAD"
        url = download_link_fetcher.fetch(scene_data)
        return false if url.nil?

        command = scenes_index.command(scene_data, url, :download)
        if config.dry_run?
          XXXDownload.logger.info "#{TAG}: WILL DOWNLOAD #{command}"
          return
        end

        start_download(scene_data, command)
      rescue APIError => e
        XXXDownload.logger.error("[#{TAG}: DIRECT DOWNLOAD FAIL] #{e.message}")
        false
      end

      # @param [Data::Scene] scene_data
      def download_using_stream(scene_data)
        XXXDownload.logger.trace "[#{TAG}] ATTEMPT DOWNLOAD USING STREAMING LINKS"
        streaming_links = streaming_link_fetcher.fetch(scene_data)
        return false if streaming_links.nil?

        scene_data = scene_data.add_streaming_links(streaming_links)
        url = scene_data.streaming_links.send(config.quality.to_sym)
        command = scenes_index.command(scene_data, url, :stream)
        if config.dry_run?
          XXXDownload.logger.info "#{TAG}: WILL DOWNLOAD #{command}"
          return
        end

        start_download(scene_data, command)
      rescue APIError => e
        XXXDownload.logger.error("[#{TAG}: DIRECT DOWNLOAD FAIL] #{e.message}")
        if e.is_a?(XXXDownload::RedirectedError)
          raise FatalError, "Redirection suggests possible cookie/token expiry. Regenerate token and try again."
        end
      end

      # @param [Data::Scene] scene_data
      # @return [Boolean]
      def start_download(scene_data, command)
        XXXDownload.logger.trace "[#{TAG}: COMMAND] #{command}"
        Open3.popen2e(command) do |_, stdout_and_stderr, thread|
          output = ""
          XXXDownload.logger.info "[PID] #{thread.pid} [FILENAME] #{scene_data.file_name.to_s.colorize(:green)}"
          stdout_and_stderr.each do |line|
            output = line
            XXXDownload.file_logger.info("#{thread.pid} -- #{line}")
          end

          exit_status = thread.value
          if exit_status == 0 # rubocop:disable Style/NumericPredicate
            return false unless valid_file_size?(scene_data)

            store.save_download(scene_data)
            XXXDownload.logger.info "[#{TAG}: DOWNLOAD COMPLETE] #{scene_data.file_name}"
            return true
          else
            XXXDownload.logger.error "[#{TAG}: DOWNLOAD FAIL] #{scene_data.file_name} -- #{output.strip}"
            return false
          end
        end
        false
      end

      def valid_file_size?(scene_data)
        file = find_file(scene_data)

        if file.nil?
          XXXDownload.logger.warn "[#{TAG}: FILENAME RESOLUTION FAILURE] #{scene_data.title}"
          return false
        end

        size = File.size?(file)
        if size.nil?
          XXXDownload.logger.warn "[#{TAG}: FILE SIZE CALCULATION ERROR] #{scene_data.title}"
          return false
        end

        raise FileSizeTooSmallError.new(file, size) if size < 2000

        true
      rescue FileSizeTooSmallError => e
        rate_limited = XXXDownload.config.post_download_rate_limiting_site?(file)
        ::FileUtils.remove_file(file)
        raise FatalError, "You have been rate limited and cannot download more videos." if rate_limited

        XXXDownload.logger.warn e.message
        false
      end

      #
      # Checks if the file exists in the current directory or the directories
      # provided by the user in the configuration. Returns the name of the file
      # if found, otherwise returns false.
      #
      # @param [Data::Scene] scene_data
      # @return [String, FalseClass]
      def file_downloaded?(scene_data)
        search_dirs = [Dir.pwd].concat(XXXDownload.config.pre_download_search_dir)
        search_dirs.each do |dir|
          Dir.chdir(dir) do
            XXXDownload.logger.trace "[#{TAG}: SEARCH #{scene_data.title}] #{dir}"
            file = find_file(scene_data)
            return file if file.present?
          end
        end
        false
      rescue RuntimeError => e
        XXXDownload.logger.trace "[#{TAG}] #{e.message}"
        XXXDownload.logger.warn "[#{TAG}] Failed to check if the file is downloaded in pre_download_search_dir. " \
                                "Your file may be re-downloaded."
        false
      end

      def find_file(scene_data)
        # extensions for partially downloaded files. used to resume downloads
        partial_extensions = %w[.part .aria2]
        # replace all non-word characters with `?` for globbing to work
        search_str = "#{scene_data.file_name.gsub(/[^-\w\s]/, "?")}.*"
        Dir[search_str].reject { |f| partial_extensions.include?(File.extname(f)) }.first
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
