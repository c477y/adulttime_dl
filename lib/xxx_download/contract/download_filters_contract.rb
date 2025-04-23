# frozen_string_literal: true

require "open3"

module XXXDownload
  module Contract
    class DownloadFiltersContract < Dry::Validation::Contract
      include Utils

      SUPPORTED_SITES = [
        "adulttime", # needs fixing
        "archangel", # needs fixing
        "blowpass", # needs fixing
        "cumlouder",
        "evilangel",
        "houseofyre", # needs fixing
        "julesjordan",
        "loveherfilms", # needs fixing
        "manuelferrara",
        "newsensations",
        "pornfidelity",
        "rickysroom",
        "s3xus",
        "scoregroup", # needs fixing
        "spizoo",
        "ztod"
      ].freeze

      DEPRECATED_SITES = %w[
        goodporn
        pornve
      ].freeze

      SUPPORTED_SITES_SPELL_CHECKER = DidYouMean::SpellChecker.new(dictionary: SUPPORTED_SITES)

      SUPPORTED_DOWNLOADERS = [
        Constants::CLIENT_YOUTUBE_DL,
        Constants::CLIENT_YT_DLP,
        Constants::CLIENT_WGET
      ].freeze
      AVAILABLE_QUALITIES = %w[4k fhd hd sd].freeze

      json do # rubocop:disable Metrics/BlockLength
        required(:site).value(:string)
        optional(:download_filters).hash do
          optional(:skip_studios).maybe(array[:string])
          optional(:skip_performers).maybe(array[:string])
          optional(:skip_keywords).maybe(array[:string])
          optional(:oldest_year).maybe(:integer)
          optional(:skip_lesbian).maybe(:bool)
          optional(:minimum_duration).maybe(:string)
          optional(:skip_trans).maybe(:bool)
        end

        optional(:cookie_file).maybe(:string)
        optional(:store).maybe(:string)
        required(:downloader).value(:string)
        required(:download_dir).value(:string)
        required(:quality).value(:string)
        required(:parallel).value(:integer)
        optional(:dry_run).value(:bool)
        optional(:downloader_flags).maybe(:string)
        optional(:cdp_host).maybe(:string)
        optional(:pre_download_search_dir).maybe(array[:string])
        optional(:headless).maybe(:bool)
        optional(:site_config).hash do
          optional(:blowpass).hash do
            optional(:algolia_application_id).maybe(:string)
            optional(:algolia_api_key).maybe(:string)
          end
        end
        optional(:stash_app).hash do
          optional(:url).maybe(:string)
          optional(:api_token).maybe(:string)
        end
        required(:urls).hash do
          optional(:page).maybe(array[:string]) # all scenes listed on a page
          optional(:performers).maybe(array[:string]) # all scenes for a given performer
          optional(:movies).maybe(array[:string]) # all scenes that belong to the movie
          optional(:scenes).maybe(array[:string]) # individual scenes
        end
      end

      rule(:site) do
        if DEPRECATED_SITES.include?(value)
          key.failure("#{value} is no longer supported")
        elsif !SUPPORTED_SITES.include?(value)
          possible_sites = SUPPORTED_SITES_SPELL_CHECKER.correct(value)
          if possible_sites.length == 1
            key.failure("#{value} is not a valid site. Did you mean #{possible_sites.first}?")
          else
            key.failure("#{value} is not supported. Provide one of #{SUPPORTED_SITES.join(", ")}")
          end
        end
      end

      rule(:pre_download_search_dir) do
        value.each { |x| key.failure("invalid directory '#{x}'") unless valid_dir?(x) }
      end

      rule(:store) do
        next unless value.nil?

        key.failure("does not exist or cannot be read") unless valid_file?(value)
      end

      rule(download_filters: :oldest_year) do
        key.failure("must be a valid year") if value < 1980 || value > Time.now.year
      end

      rule(download_filters: :minimum_duration) do
        invalid_format_msg = "must be a valid duration in the format MM:SS"
        key.failure(invalid_format_msg) unless value.match?(/\d{2}:\d{2}/)
        invalid_duration_msg = "must be more than 00 and less than 60"
        mm = value.split(":").first.to_i
        ss = value.split(":").last.to_i
        key.failure(invalid_duration_msg) if mm.negative? || mm > 59 || ss.negative? || ss > 59
      end

      rule(:downloader) do
        unless SUPPORTED_DOWNLOADERS.include?(value)
          key.failure("#{value} is not supported. Provide one of #{SUPPORTED_DOWNLOADERS.join(", ")}")
        end

        if value == Constants::CLIENT_YOUTUBE_DL
          XXXDownload.logger.warn "youtube-dl is deprecated. Please use yt-dlp instead."
        end

        stdout, stderr, status = Open3.capture3("#{value} --version")
        if status.success?
          XXXDownload.logger.debug "#{value} installed with version #{stdout.strip}"
        else
          XXXDownload.logger.fatal "[DOWNLOADER_CHECK_ERROR] #{stderr.strip}"
          key.failure("is not installed or unavailable on $PATH.")
        end
      end

      rule(:download_dir) do
        key.failure("is not a valid directory.") unless File.directory?(value)
      end

      rule(:quality) do
        unless AVAILABLE_QUALITIES.include?(value)
          key.failure("#{value} is not supported. Provide one of #{AVAILABLE_QUALITIES.join(", ")}")
        end
      end

      rule(:parallel) do
        key.failure("parallelism cannot be less than 1") if value < 1
        if value > 5
          XXXDownload.logger.warn("Do not set parallelism to more than 5 as it can result in unexpected behaviour")
        end
      end
    end
  end
end
