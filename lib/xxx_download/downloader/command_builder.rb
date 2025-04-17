# frozen_string_literal: true

module XXXDownload
  module Downloader
    class CommandBuilder
      class BadCommandError < StandardError; end

      #
      # Generate a command that can use used for direct downloads
      # Provide a block that configures the mandatory parameters
      # 1. path
      # 2. url
      # @yield [XXXDownload::Downloader::CommandBuilder] builder
      # @return [String] a command to run in shell to download a scene
      # rubocop:disable Layout/LineLength
      def self.build_basic
        builder = new
        builder.download_client(XXXDownload.config.downloader)
        builder.add_default_flags
        builder.cookie(XXXDownload.config.cookie_file)              if XXXDownload.config.downloader_requires_cookie?
        builder.verbose                                             if %w[debug trace extra].include?(XXXDownload.logger.level.to_s.downcase)
        builder.parallel(XXXDownload.config.parallel)               if XXXDownload.config.parallel
        builder.external_flags(XXXDownload.config.downloader_flags) if XXXDownload.config.downloader_flags

        raise FatalError, "[COMMAND BUILDER] no configuration provided" unless block_given?

        yield builder
        builder.build
      end
      # rubocop:enable Layout/LineLength

      def self.build
        builder = new
        raise FatalError, "[COMMAND BUILDER] no configuration provided" unless block_given?

        yield builder
        builder.build
      end

      def initialize
        command = Command.new
        @command = command
      end

      def download_client(client)
        command.download_client = client
      end

      def url(url)
        command.url = " \"#{url}\""
      end

      def path(filename, path = "", ext = "%(ext)s")
        command.path = case command.download_client
                       when Constants::CLIENT_WGET
                         " -O '#{File.join(path, filename)}.mp4'"
                       else
                         " -o '#{File.join(path, filename)}.#{ext}'"
                       end
      end

      def merge_parts
        case command.download_client
        when Constants::CLIENT_WGET
          command.merge_parts = nil
        when Constants::CLIENT_YOUTUBE_DL, Constants::CLIENT_YT_DLP
          command.merge_parts = "--merge-output-format mkv"
        else
          raise FatalError, "[COMMAND BUILDER] Unknown downloader #{command.download_client}"
        end
      end

      def external_flags(flag)
        command.external_flags = flag
      end

      def add_default_flags
        case command.download_client
        when Constants::CLIENT_WGET
          command.defaults = "--continue --tries=5 --retry-connrefused --waitretry=5 --timeout=60"
        when Constants::CLIENT_YOUTUBE_DL, Constants::CLIENT_YT_DLP
          command.defaults = nil
        else
          raise FatalError, "[COMMAND BUILDER] Unknown downloader #{command.download_client}"
        end
      end

      # Parallel downloads are only supported by yt-dlp
      def parallel(parallel)
        case command.download_client
        when Constants::CLIENT_YT_DLP
          command.parallel = "--concurrent-fragments #{parallel}"
        when Constants::CLIENT_YOUTUBE_DL, Constants::CLIENT_WGET
          command.parallel = nil
        else
          raise FatalError, "[COMMAND BUILDER] Unknown downloader #{command.download_client}"
        end
      end

      def quality(max_res = "720")
        case command.download_client
        when Constants::CLIENT_YT_DLP, Constants::CLIENT_YOUTUBE_DL
          command.quality = "-f 'bestvideo[height<=#{max_res}]+bestaudio/best[height<=#{max_res}]'"
        when Constants::CLIENT_WGET
          command.quality = nil
        else
          raise FatalError, "[COMMAND BUILDER] Unknown downloader #{command.download_client}"
        end
      end

      def verbose
        case command.download_client
        when Constants::CLIENT_YT_DLP, Constants::CLIENT_YOUTUBE_DL
          command.verbosity = "--verbose --dump-pages"
        when Constants::CLIENT_WGET
          command.verbosity = "--verbose"
        else
          raise FatalError, "[COMMAND BUILDER] Unknown downloader #{command.download_client}"
        end
      end

      def cookie(file_path)
        case command.download_client
        when Constants::CLIENT_YT_DLP, Constants::CLIENT_YOUTUBE_DL
          command.cookie = "--cookies #{file_path}"
        when Constants::CLIENT_WGET
          command.cookie = "--load-cookies #{file_path}"
        else
          raise FatalError, "[COMMAND BUILDER] Unknown downloader #{command.download_client}"
        end
      end

      def build
        unless command.valid?
          raise BadCommandError, "[BAD COMMAND GENERATED] Missing #{command.missing_keys.join(", ")}."
        end

        command.build
      end

      private

      attr_reader :command
    end

    class Command
      def initialize
        @command = ""
      end

      attr_accessor :download_client

      attr_writer :url, :cookie, :path, :verbosity, :defaults,
                  :external_flags, :merge_parts, :parallel, :quality

      def build
        [@download_client, @url, @cookie, @path, @verbosity, @defaults,
         @external_flags, @merge_parts, @parallel, @quality].compact.map(&:strip).join(" ")
      end

      def valid?
        MANDATORY_KEYS.all? { |key| instance_variable_get("@#{key}").present? }
      end

      def missing_keys
        MANDATORY_KEYS.select { |key| instance_variable_get("@#{key}").nil? }
      end

      MANDATORY_KEYS = %i[download_client url path].freeze
    end
  end
end
