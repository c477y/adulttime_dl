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
        scene_data = scene_data.refresh(config.cookie) if scene_data.refresh_required?

        if store.downloaded?(scene_data.key)
          AdultTimeDL.logger.info "[ALREADY DOWNLOADED] #{scene_data.file_name}"
          return
        end

        return if file_exists?(scene_data)

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
        elsif (scene = stash_app&.scene(scene_data))
          store.save_download(scene_data, is_downloaded: true)
          AdultTimeDL.logger.info "[STASH: FILE EXISTS] #{scene_data.title}"
          AdultTimeDL.logger.debug "TITLE: #{scene["title"]}"
          AdultTimeDL.logger.debug "PATH: #{scene["files"]&.first&.[]("path")}"
          return true
        end
        false
      end

      def stash_app
        return @stash_app if defined?(@stash_app)

        @stash_app ||=
          begin
            return nil if config.stash_app&.url.nil?

            require "adulttime_dl/net/stash_app"
            app = Net::StashApp.new(config)
            app.setup_credentials!
            app
          end
      end

      # @param [Data::Scene] scene_data
      def download_using_video_url(scene_data)
        url = download_link_fetcher.fetch(scene_data)
        return false if url.nil?

        command = generate_command(scene_data, url)
        if config.dry_run?
          AdultTimeDL.logger.info "WILL DOWNLOAD #{command}"
        else
          start_download(scene_data, command)
        end
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
        if config.dry_run?
          AdultTimeDL.logger.info "WILL DOWNLOAD #{command}"
        else
          start_download(scene_data, command)
        end
      rescue APIError => e
        AdultTimeDL.logger.error("[DIRECT DOWNLOAD FAIL] #{e.message}")
        if e.is_a?(AdultTimeDL::RedirectedError)
          raise FatalError, "Redirection suggests possible cookie/token expiry. Regenerate token and try again."
        end
      end

      # @param [Data::Scene] scene_data
      # @return [TrueClass, FalseClass]
      def start_download(scene_data, command)
        AdultTimeDL.logger.debug command
        Open3.popen2e(command) do |_, stdout_and_stderr, thread|
          output = ""
          AdultTimeDL.logger.info "[PID] #{thread.pid} [FILE] #{scene_data.file_name.to_s.colorize(:green)}"
          stdout_and_stderr.each do |line|
            output = line
            AdultTimeDL.file_logger.info("#{thread.pid} -- #{line}")
          end

          exit_status = thread.value
          if exit_status != 0
            store.save_download(scene_data, is_downloaded: false)
            AdultTimeDL.logger.error "[DOWNLOAD_FAIL] #{scene_data.file_name} -- #{output.strip}"
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
        case config.site
        when "julesjordan" then JulesJordanCommand.build(config, scene_data, url)
        when "archangel" then ArchAngelCommand.build(config, scene_data, url)
        when "goodporn" then GoodPornCommand.build(config, scene_data, url)
        else
          using_default_link = !scene_data.streaming_links&.default.nil?
          CommandBuilder.new
                        .with_download_client(client)
                        .with_merge_parts(false)
                        .with_path(scene_data.file_name, config.download_dir)
                        .with_external_flags(config.downloader_flags)
                        .with_verbosity(config.verbose)
                        .with_cookie(config.cookie_file, config.downloader_requires_cookie?)
                        .with_url(url).build
        end
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
        # Dir.chdir(config.download_dir) do
        filename = "#{scene_data.file_name}.mp4"
        unless File.file?(filename) && File.exist?(filename)
          AdultTimeDL.logger.warn "[FILENAME RESOLUTION FAILURE] #{File.join(Dir.pwd, filename)}"
        end
        if File.file?(filename) && File.exist?(filename) && File.size?(filename) < 20_000
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
        # end
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
