# frozen_string_literal: true

require "open3"

module XXXDownload
  module Contract
    class DownloadFiltersContract < Dry::Validation::Contract
      include XXXDownload::Utils

      SUPPORTED_SITES = %w[
        adulttime
        archangel
        blowpass
        cumlouder
        goodporn
        houseofyre
        julesjordan
        loveherfilms
        manuelferrara
        pornve
        scoregroup
        sxyporn
        ztod
      ].freeze

      SUPPORTED_SITES_SPELL_CHECKER = DidYouMean::SpellChecker.new(dictionary: SUPPORTED_SITES)

      SUPPORTED_DOWNLOADERS = %w[youtube-dl yt-dlp].freeze
      COOKIE_REQUIRED_SITES = %w[
        adulttime
        archangel
        houseofyre
        julesjordan
        manuelferrara
        loveherfilms
        ztod
      ].freeze
      AVAILABLE_QUALITIES = %w[4k fhd hd sd].freeze

      json do
        required(:site).value(:string)
        optional(:download_filters).hash do
          optional(:skip_studios).maybe(array[:string])
          optional(:skip_performers).maybe(array[:string])
          optional(:skip_keywords).maybe(array[:string])
          optional(:oldest_year).maybe(:integer)
          optional(:skip_lesbian).maybe(:bool)
          optional(:minimum_duration).maybe(:string)
        end

        optional(:cookie_file).maybe(:string)
        optional(:store).maybe(:string)
        required(:downloader).value(:string)
        required(:download_dir).value(:string)
        required(:quality).value(:string)
        required(:parallel).value(:integer)
        optional(:dry_run).value(:bool)
        optional(:downloader_flags).maybe(:string)
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
        unless SUPPORTED_SITES.include?(value)
          possible_sites = SUPPORTED_SITES_SPELL_CHECKER.correct(value)
          if possible_sites.length == 1
            key.failure("#{value} is not a valid site. Did you mean #{possible_sites.first}?")
          else
            key.failure("#{value} is not supported. Provide one of #{SUPPORTED_SITES.join(", ")}")
          end
        end
      end

      rule(:cookie_file, :site) do
        if cookie_required?(values[:site]) && !valid_file?(values[:cookie_file])
          key.failure("does not exist or cannot be read")
        end
      end

      rule(:store) do
        if !value.nil? # download store will be created.
          nil
        else
          key.failure("does not exist or cannot be read") unless valid_file?(value)
        end
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
          key.failure("#{value} is not supported. Provide one of #{SUPPORTED_SITES.join(", ")}")
        end

        stdout, stderr, status = Open3.capture3("#{value} --version")
        if status.success?
          XXXDownload.logger.info "#{value} installed with version #{stdout.strip}"
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
        key.failure("do not set parallelism to more than 5 as it can result in unexpected behaviour") if value > 5
      end

      private

      def cookie_required?(site)
        COOKIE_REQUIRED_SITES.include?(site)
      end
    end
  end
end
