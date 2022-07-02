# frozen_string_literal: true

module AdultTimeDL
  module Downloader
    class CommandBuilder
      def initialize
        @command = String.new
      end

      def with_download_client(download_client)
        @download_client = download_client
        command << download_client
        self
      end

      def with_merge_parts(merge_parts = false) # rubocop:disable Style/OptionalBooleanParameter
        merge_parts ? command << " --merge-output-format mkv" : command
        self
      end

      def with_parallism(parallel = 1)
        return self if download_client == "youtube-dl"

        command << " --concurrent-fragments #{parallel}"
        self
      end

      def with_path(filename, path = "")
        complete_path = File.join(path, filename)
        command << " -o '#{complete_path}.%(ext)s'"
        self
      end

      def with_url(url)
        command << " \"#{url}\""
        self
      end

      def build
        command
      end

      private

      attr_reader :download_client, :command
    end
  end
end
