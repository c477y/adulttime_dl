# frozen_string_literal: true

module XXXDownload
  module Data
    class Config < Base
      SUPPORTED_DOWNLOAD_CLIENTS = Types::String.enum(
        Constants::CLIENT_YOUTUBE_DL,
        Constants::CLIENT_YT_DLP,
        Constants::CLIENT_WGET
      )

      QUALITY = Types::String.enum("fhd", "hd", "sd")

      # rubocop:disable Layout/HashAlignment
      MODULE_NAME = {
        "adulttime"     => "AdultTime",
        "archangel"     => "ArchAngel",
        "blowpass"      => "Blowpass",
        "cumlouder"     => "CumLouder",
        "goodporn"      => "Goodporn",
        "evilangel"     => "EvilAngel",
        "houseofyre"    => "HouseOFyre",
        "julesjordan"   => "JulesJordan",
        "loveherfilms"  => "LoveHerFilms",
        "manuelferrara" => "ManuelFerrara",
        "newsensations" => "NewSensations",
        "pornfidelity"  => "Pornfidelity",
        "pornve"        => "Pornve",
        "rickysroom"    => "RickysRoom",
        "s3xus"         => "S3xus",
        "scoregroup"    => "ScoreGroup",
        "spizoo"        => "Spizoo",
        "ztod"          => "Ztod"
      }.freeze
      # rubocop:enable Layout/HashAlignment

      STREAMING_LINKS_SUFFIX = "StreamingLinks"
      DOWNLOAD_LINKS_SUFFIX = "DownloadLinks"
      INDEX_SUFFIX = "Index"

      # Sites that only support downloads using direct links
      # The playback option in these sites just stream the direct
      # download
      STREAMING_UNSUPPORTED_SITE = %w[
        adulttime
        archangel
        blowpass
        cumlouder
        evilangel
        goodporn
        houseofyre
        julesjordan
        manuelferrara
        newsensations
        pornfidelity
        rickysroom
        s3xus
        scoregroup
        spizoo
        ztod
      ].freeze

      # Sites that only support streaming. This may be because downloading
      # is not allowed by the site OR the download option is behind a paywall
      DOWNLOADING_UNSUPPORTED_SITE = %w[
        loveherfilms
        pornve
      ].freeze

      COOKIE_REQUIRED_TO_DOWNLOAD_SITE = %w[
        loveherfilms
      ].freeze

      POST_DOWNLOAD_RATE_LIMITING_SITES = %w[
        adulttime
        evilangel
        ztod
      ].freeze

      def initialize(attributes)
        attributes[:exec_path] = Dir.pwd
        super(attributes)
      end

      attribute :site, Types::String
      attribute? :exec_path, Types::String
      attribute :download_filters, DownloadFilters
      attribute :cookie_file, Types::String.optional
      attribute :store, Types::String
      attribute :downloader, SUPPORTED_DOWNLOAD_CLIENTS
      attribute :download_dir, Types::String
      attribute :quality, QUALITY
      attribute :parallel, Types::Integer
      attribute? :dry_run, Types::Bool.optional
      attribute :downloader_flags, Types::String.default("")
      attribute? :cdp_host, Types::String.optional
      attribute :pre_download_search_dir, Types::Array.of(Types::String).default([].freeze)
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

      delegate :performers, :movies, :scenes, :page, to: :urls

      def abs_cookie_file_path
        File.join(exec_path, cookie_file)
      end

      def cookie
        return unless File.exist?(abs_cookie_file_path)

        jar = HTTP::CookieJar.new
        jar.load(abs_cookie_file_path, :cookiestxt)
        HTTP::Cookie.cookie_value(jar.cookies)
      end

      def delete_cookie_file
        return unless File.exist?(abs_cookie_file_path)

        ::FileUtils.rm(File.join(abs_cookie_file_path, cookie_file))
      end

      def store_cookies(cookies)
        jar = HTTP::CookieJar.new
        cookies.each { |c| jar.add(c) }
        jar.save(abs_cookie_file_path, format: :cookiestxt, session: true)
      end

      def dry_run?
        dry_run == true
      end

      #
      # AdultTime and ZeroTolerance have a rate limiting system where the server
      # will allow us to generate the download/streaming links but the links will
      # return a rate-limiting message when accessed.
      #
      # @return [Boolean]
      def post_download_rate_limiting_site?(file)
        return false unless POST_DOWNLOAD_RATE_LIMITING_SITES.include?(site)

        # Read the file to check if server rate-limited us
        sniff = File.read(file, 100)
        sniff = sniff.split(":").map(&:strip)

        # limit reached: <IP>:<USER ID>
        sniff.first == "limit reached"
      end

      def streaming_link_fetcher
        return Net::NoopLinkFetcher.new if STREAMING_UNSUPPORTED_SITE.include?(site)

        generate_class(site, STREAMING_LINKS_SUFFIX)
      end

      def download_link_fetcher
        return Net::NoopLinkFetcher.new if DOWNLOADING_UNSUPPORTED_SITE.include?(site)

        generate_class(site, DOWNLOAD_LINKS_SUFFIX)
      end

      def scenes_index
        generate_class(site, INDEX_SUFFIX)
      end

      def downloader_requires_cookie?
        COOKIE_REQUIRED_TO_DOWNLOAD_SITE.include?(site)
      end

      # @param [XXXDownload::Data::Scene] scene
      def skip_scene?(scene)
        download_filters.skip?(scene)
      end

      # Get the site-specific configuration for the current site
      def current_site_config
        to_h.dig(:site_config, site.to_sym)
      end

      private

      def generate_class(site, suffix)
        "XXXDownload::Net::#{MODULE_NAME[site]}#{suffix}".constantize.new
      rescue NameError => e
        raise XXXDownload::FatalError, "[INIT FAILURE] #{"XXXDownload::Net::#{MODULE_NAME[site]}#{suffix}"}\n" \
                                       "Error: #{e.message}"
      end
    end
  end
end
