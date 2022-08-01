# frozen_string_literal: true

module AdultTimeDL
  module Data
    class Config < Base
      extend Forwardable

      SUPPORTED_DOWNLOAD_CLIENTS = Types::String.enum("youtube-dl", "yt-dlp")
      SUPPORTED_SITES = Types::String.enum("adulttime", "ztod", "loveherfilms", "pornve")
      QUALITIES = Types::String.enum("fhd", "hd", "sd")
      MODULE_NAME = {
        "adulttime" => "AdultTime",
        "ztod" => "ZTOD",
        "loveherfilms" => "LoveHerFilms",
        "pornve" => "PornVE"
      }.freeze
      STREAMING_LINKS_SUFFIX = "StreamingLinks"
      DOWNLOAD_LINKS_SUFFIX = "DownloadLinks"
      INDEX_SUFFIX = "Index"

      attribute :site, SUPPORTED_SITES
      attribute :download_filters, DownloadFilters
      attribute :cookie_file, Types::String.optional
      attribute :store, Types::String
      attribute :downloader, SUPPORTED_DOWNLOAD_CLIENTS
      attribute :download_dir, Types::String
      attribute :quality, QUALITIES
      attribute :parallel, Types::Integer
      attribute :verbose, Types::Bool
      attribute :urls, URLs

      def_delegators :urls, :all_scenes, :performers, :movies, :scenes

      def cookie
        jar = HTTP::CookieJar.new
        jar.load(cookie_file, :cookiestxt)
        HTTP::Cookie.cookie_value(jar.cookies)
      end

      def streaming_link_fetcher
        generate_class(site, STREAMING_LINKS_SUFFIX)
      end

      def download_link_fetcher
        case site
        when "loveherfilms" then Net::NOOPDownloadLinks.new
        when "pornve" then Net::NOOPDownloadLinks.new
        else generate_class(site, DOWNLOAD_LINKS_SUFFIX)
        end
      end

      def scenes_index
        generate_class(site, INDEX_SUFFIX)
      end

      def downloader_requires_cookie?
        ["loveherfilms"].include?(site)
      end

      # @param [Data::Scene] scene
      def skip_scene?(scene)
        download_filters.skip?(scene)
      end

      private

      def generate_class(site, suffix)
        klass = "AdultTimeDL::Net::#{MODULE_NAME[site]}#{suffix}"
        Object.const_get(klass).new(self)
      rescue StandardError => e
        raise FatalError, "#{e.class} #{e.message}"
      end
    end
  end
end
