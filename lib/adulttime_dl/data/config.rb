# frozen_string_literal: true

module AdultTimeDL
  module Data
    class Config < Base
      SUPPORTED_DOWNLOAD_CLIENTS = Types::String.default("youtube-dl").enum("youtube-dl", "yt-dlp")
      QUALITIES = Types::String.default("hd").enum("fhd", "hd", "sd")

      attribute :cookie_file, Types::String.default("cookie.txt")
      attribute :downloader, SUPPORTED_DOWNLOAD_CLIENTS
      attribute :download_dir, Types::String.default(".")
      attribute :store, Types::String.default("adt_download_status.store")
      attribute :performer_file, Types::String.default("performers.yml")
      attribute :parallel, Types::Integer.default(1)
      attribute :quality, QUALITIES
      attribute :verbose, Types::Bool.default(false)
      attribute :skip_studios, Types::String.default("skip_studios.yml")
      attribute :skip_lesbian, Types::Bool.default(false)

      # TODO: Implement downloading scenes based on movie names or individual scene URLs
      # attribute :movie_file, Types::String.default("movie.yml")
      # attribute :scene_file, Types::String.default("scene.yml")

      def skip_lesbian?
        skip_lesbian
      end

      def validate_downloader!
        stdout, stderr, status = Open3.capture3("#{downloader} --version")
        raise FatalError, stderr unless status.success?

        AdultTimeDL.logger.info "#{downloader} installed with version #{stdout}"
        nil
      end

      def blacklisted_studios
        @blacklisted_studios ||=
          begin
            return Set.new unless valid_file?(skip_studios)

            contents = load_yaml!(skip_studios)
            AdultTimeDL.logger.info "Reading blocked studios from #{skip_studios}"
            AdultTimeDL.logger.info "\t#{contents.join(", ")}"
            clean_contents = contents.map(&:downcase).map { |s| s.gsub(/\W+/i, "") }
            Set.new(clean_contents)
          end
      end

      def cookie!
        raise FatalError, "Unable to read cookie file" unless valid_file?(cookie_file)

        File.read(cookie_file).strip
      end

      def load_performers!
        raise FatalError, "Unable to find file #{performer_file}" unless valid_file?(performer_file)

        load_yaml!(performer_file)
      end

      private

      def valid_file?(file)
        file && File.file?(file) && File.exist?(file)
      end

      def load_yaml!(file)
        contents = YAML.load_file(file)
        raise FatalError, "#{file}: Invalid YAML format" unless contents

        return contents if contents.is_a?(Array)

        raise FatalError, "#{file}: Invalid YAML contents. Was expecting Array, but received #{contents.class}"
      end
    end
  end
end
