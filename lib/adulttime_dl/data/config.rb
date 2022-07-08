# frozen_string_literal: true

module AdultTimeDL
  module Data
    class Config < Base
      SUPPORTED_DOWNLOAD_CLIENTS = Types::String.enum("youtube-dl", "yt-dlp")
      SUPPORTED_SITES = Types::String.enum("adulttime", "ztod")
      QUALITIES = Types::String.enum("fhd", "hd", "sd")

      attribute :cookie, Types::String
      attribute :downloader, SUPPORTED_DOWNLOAD_CLIENTS
      attribute :download_dir, Types::String
      attribute :store, Types::String
      attribute :performers_l, Types::Array.of(Types::String)
      attribute :movies_l, Types::Array.of(Types::String)
      attribute :parallel, Types::Integer
      attribute :quality, QUALITIES
      attribute :verbose, Types::Bool
      attribute :download_filters_l, DownloadFilters
      attribute :site, SUPPORTED_SITES

      alias performers performers_l
      alias movies movies_l
      alias download_filters download_filters_l

      def validate_downloader!
        stdout, stderr, status = Open3.capture3("#{downloader} --version")
        raise FatalError, stderr unless status.success?

        AdultTimeDL.logger.info "#{downloader} installed with version #{stdout.strip}"
        nil
      end

      def streaming_link_fetcher
        case site
        when "adulttime" then Net::AdultTimeStreamingLinks.new(self)
        when "ztod" then Net::ZTODStreamingLinks.new(self)
        else raise FatalError, "received unexpected site name #{site}"
        end
      end

      def download_link_fetcher
        case site
        when "adulttime" then Net::AdultTimeDownloadLinks.new(self)
        when "ztod" then Net::ZTODDownloadLinks.new(self)
        else raise FatalError, "received unexpected site name #{site}"
        end
      end

      def scenes_index
        case site
        when "adulttime" then Net::AdultTimeIndex.new(self)
        when "ztod" then Net::ZTODIndex.new(self)
        else raise FatalError, "received unexpected site name #{site}"
        end
      end

      # @param [Data::AlgoliaScene] scene
      def skip_scene?(scene)
        download_filters.skip?(scene)
      end
    end
  end
end
