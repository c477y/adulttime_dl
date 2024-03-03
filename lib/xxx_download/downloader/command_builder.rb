# frozen_string_literal: true

module XXXDownload
  module Downloader
    class CommandBuilder
      class BadCommandError < StandardError; end

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
        command.path = " -o '#{File.join(path, filename)}.#{ext}'"
      end

      def merge_parts
        command.merge_parts = "--merge-output-format mkv"
      end

      # Extra arguments for the downloader. Example
      # --external-downloader aria2c --external-downloader-args '-x 7'
      def external_flags(flag)
        command.external_flags = flag
      end

      def parallel(parallel)
        return if command.download_client == "youtube-dl"

        command.parallel = "--concurrent-fragments #{parallel}"
      end

      def quality(max_res = "720")
        command.quality = " -f 'bestvideo[height<=#{max_res}]+bestaudio/best[height<=#{max_res}]'"
      end

      def verbose
        command.verbosity = "--verbose --dump-pages"
      end

      def cookie(file_path)
        command.cookie = "--cookies #{file_path}"
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

      attr_writer :url, :cookie, :path, :verbosity,
                  :external_flags, :merge_parts, :parallel, :quality

      def build
        [@download_client, @url, @cookie, @path, @verbosity,
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
