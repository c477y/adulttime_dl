# frozen_string_literal: true

module AdultTimeDL
  module Data
    class Config < Base
      extend Forwardable

      SUPPORTED_DOWNLOAD_CLIENTS = Types::String.enum("youtube-dl", "yt-dlp")
      QUALITY = Types::String.enum("fhd", "hd", "sd")
      MODULE_NAME = {
        "adulttime" => "AdultTime",
        "archangel" => "ArchAngel",
        "blowpass" => "BlowPass",
        "cumlouder" => "CumLouder",
        "goodporn" => "GoodPorn",
        "houseofyre" => "HouseOFyre",
        "julesjordan" => "JulesJordan",
        "loveherfilms" => "LoveHerFilms",
        "manuelferrara" => "JulesJordan",
        "pornve" => "PornVE",
        "scoregroup" => "ScoreGroup",
        "sxyporn" => "SxyPorn",
        "ztod" => "ZTOD"
      }.freeze
      STREAMING_LINKS_SUFFIX = "StreamingLinks"
      DOWNLOAD_LINKS_SUFFIX = "DownloadLinks"
      INDEX_SUFFIX = "Index"
      STREAMING_UNSUPPORTED_SITE = %w[
        archangel
        cumlouder
        goodporn
        julesjordan
        manuelferrara
        scoregroup
      ].freeze
      DOWNLOADING_UNSUPPORTED_SITE = %w[
        loveherfilms
        pornve
      ].freeze

      attribute :site, Types::String
      attribute :download_filters, DownloadFilters
      attribute :cookie_file, Types::String.optional
      attribute :store, Types::String
      attribute :downloader, SUPPORTED_DOWNLOAD_CLIENTS
      attribute :download_dir, Types::String
      attribute :quality, QUALITY
      attribute :parallel, Types::Integer
      attribute :verbose, Types::Bool
      attribute? :dry_run, Types::Bool.optional
      attribute :downloader_flags, Types::String.default("")
      attribute? :urls, URLs
      attribute? :site_config do
        attribute? :blowpass do
          attribute? :algolia_application_id, Types::String.optional
          attribute? :algolia_api_key, Types::String.optional
        end
      end
      attribute? :stash_app do
        attribute? :url,                   Types::String.optional
        attribute? :api_token,             Types::String.optional
      end

      def_delegators :urls, :performers, :movies, :scenes

      def cookie
        return unless File.exist?(cookie_file)

        jar = HTTP::CookieJar.new
        jar.load(cookie_file, :cookiestxt)
        HTTP::Cookie.cookie_value(jar.cookies)
      end

      def dry_run?
        dry_run == true
      end

      def streaming_link_fetcher
        return Net::NOOPDownloadLinks.new if STREAMING_UNSUPPORTED_SITE.include?(site)

        generate_class(site, STREAMING_LINKS_SUFFIX)
      end

      def download_link_fetcher
        return Net::NOOPDownloadLinks.new if DOWNLOADING_UNSUPPORTED_SITE.include?(site)

        generate_class(site, DOWNLOAD_LINKS_SUFFIX)
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

      def to_pretty_h
        to_h.tap do |hash|
          urls = {
            performers: "#{performers.length} items",
            movies: "#{movies.length} items",
            scenes: "#{scenes.length} items"
          }
          hash[:urls] = urls
        end
      end

      def inspect
        to_pretty_h.inspect
      end

      # Get the site-specific configuration for the current site
      def current_site_config
        to_h.dig(:site_config, site.to_sym)
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
