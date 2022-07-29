# frozen_string_literal: true

module AdultTimeDL
  module Utils
    DEFAULT_CONFIG = {
      "skip_studios" => [],
      "skip_performers" => [],
      "skip_lesbian" => false,
      "cookie_file" => "cookies.txt",
      "store" => "adt_download_status.store",
      "downloader" => "youtube-dl",
      "quality" => "hd"
    }.freeze
    DEFAULT_CONFIG_FILE = "config.yml"

    def validate_download_filters!(file)
      raise FatalError, "received file as nil" if file.nil?

      save_default_config! unless valid_file?(file)

      download_filters = FileUtils.read_yaml(file)
      contract = DownloadFiltersContract.new.call(download_filters)

      unless contract.errors.empty?
        messages = []
        contract.errors.messages.each do |key|
          messages << "#{key.path.join(", ")} #{key.text}"
        end
        raise FatalError, "[INVALID DOWNLOAD FILTERS] #{messages.join(", ")}"
      end

      contract.to_h.transform_keys(&:to_s)
    end

    def save_default_config!
      AdultTimeDL.logger.info "-" * 100
      AdultTimeDL.logger.info "Config option not passed to app and no config file detected in the current directory."
      AdultTimeDL.logger.info "Generating a blank configuration file to #{DEFAULT_CONFIG_FILE} This CLI will now exit."
      AdultTimeDL.logger.info "Validate the contents of the file and run the app again to start downloading."
      AdultTimeDL.logger.info "-" * 100

      File.open(DEFAULT_CONFIG_FILE, "w") do |file|
        file.write DEFAULT_CONFIG.to_yaml
      end

      raise SafeExit, "DEFAULT_FILE_GENERATION"
    end

    def valid_file?(file)
      file && File.file?(file) && File.exist?(file)
    end

    # @param [String] site
    # @return [String (frozen)]
    def base_url(site)
      case site
      when "adulttime" then Constants::ADULTTIME_BASE_URL
      when "ztod" then Constants::ZTOD_BASE_URL
      else raise FatalError, "received unexpected site name #{site}"
      end
    end
  end
end
