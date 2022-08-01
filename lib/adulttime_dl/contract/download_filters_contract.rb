# frozen_string_literal: true

module Contract
  class DownloadFiltersContract < Dry::Validation::Contract
    include AdultTimeDL::Utils

    SUPPORTED_SITES = %w[adulttime ztod loveherfilms pornve].freeze
    SUPPORTED_DOWNLOADERS = %w[youtube-dl yt-dlp].freeze
    COOKIE_REQUIRED_SITES = %w[adulttime ztod loveherfilms].freeze
    AVAILABLE_QUALITIES = %w[fhd hd sd].freeze

    json do
      required(:site).value(:string)
      optional(:skip_studios).maybe(array[:string]) # Download Filters
      optional(:skip_performers).maybe(array[:string]) # Download Filters
      optional(:skip_lesbian).maybe(:bool) # Download Filters
      optional(:cookie_file).maybe(:string)
      optional(:store).maybe(:string)
      required(:downloader).value(:string)
      required(:download_dir).value(:string)
      required(:quality).value(:string)
      required(:parallel).value(:integer)
      required(:verbose).value(:bool)
      required(:urls).hash do
        optional(:all_scenes).value(array[:string])
        optional(:performers).value(array[:string])
        optional(:movies).value(array[:string])
        optional(:scenes).value(array[:string]) # Not implemented yet
      end
    end

    rule(:site) do
      unless SUPPORTED_SITES.include?(value)
        key.failure("#{value} is not supported. Provide one of #{SUPPORTED_SITES.join(", ")}")
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

    rule(:downloader) do
      unless SUPPORTED_DOWNLOADERS.include?(value)
        key.failure("#{value} is not supported. Provide one of #{SUPPORTED_SITES.join(", ")}")
      end

      stdout, stderr, status = Open3.capture3("#{value} --version")
      if status.success?
        AdultTimeDL.logger.info "#{value} installed with version #{stdout.strip}"
      else
        AdultTimeDL.logger.fatal "[DOWNLOADER_CHECK_ERROR] #{stderr.strip}"
        key.failure("is not installed or un-available on $PATH.")
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
