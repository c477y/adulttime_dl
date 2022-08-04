# frozen_string_literal: true

module Contract
  class ConfigGenerator
    include AdultTimeDL::Utils

    DEFAULT_CONFIG = {
      "skip_studios" => [],
      "skip_performers" => [],
      "skip_lesbian" => false,
      "cookie_file" => "cookies.txt",
      "store" => "adt_download_status.store",
      "downloader" => "youtube-dl",
      "download_dir" => ".",
      "quality" => "hd",
      "parallel" => 1,
      "verbose" => false,
      "urls" => {
        "all_scenes" => [],
        "performers" => [],
        "movies" => [],
        "scenes" => []
      },
      "site_config" => {
        "blowpass" => {
          "algolia_application_id" => nil,
          "algolia_api_key" => nil
        }
      }
    }.freeze
    DEFAULT_CONFIG_FILE = "config.yml"

    def initialize(site, options)
      unless valid_file?(options[:config])
        save_default_config
        raise AdultTimeDL::SafeExit, "DEFAULT_FILE_GENERATION"
      end

      @site = site
      @options = options
    end

    def generate
      raw_config_from_file = hash_from_config_file
      config_with_overridden_flags = override_flags_from_options(raw_config_from_file)
      valid_config = validate_download_filters!(config_with_overridden_flags)
      valid_config.tap do |hash|
        hash["download_filters"] = valid_config.slice("skip_studios", "skip_performers", "skip_lesbian")
      end

      config = AdultTimeDL::Data::Config.new(valid_config)
      AdultTimeDL.logger.debug(config.to_pretty_h)
      config
    end

    def hash_from_config_file
      @hash_from_config_file ||= AdultTimeDL::FileUtils.read_yaml(options[:config]).merge("site" => site)
    end

    private

    def validate_download_filters!(config_hash)
      contract = Contract::DownloadFiltersContract.new.call(config_hash)
      unless contract.errors.empty?
        message = generate_error_message(contract.errors)
        raise AdultTimeDL::FatalError, "[INVALID DOWNLOAD FILTERS] #{message}"
      end

      contract.to_h.transform_keys(&:to_s)
    end

    def generate_error_message(errors)
      messages = []
      errors.messages.each do |key|
        messages << "[#{key.path.join(", ")}] #{key.text}"
      end
      messages.join(", ")
    end

    def override_flags_from_options(config_from_file)
      config_from_file.tap do |h|
        h["cookie_file"] = override_value(h["cookie_file"], options["cookie_file"])
        h["downloader"] = override_value(h["downloader"], options["downloader"])
        h["download_dir"] = override_value(h["download_dir"], options["download_dir"])
        h["store"] = override_value(h["store"], options["store"])
        h["parallel"] = override_value(h["parallel"], options["parallel"])
        h["quality"] = override_value(h["quality"], options["quality"])
        h["verbose"] = override_value(h["verbose"], options["verbose"])
        h["urls"].merge(**override_urls)
      end
    end

    # def download_filters
    #   raw_config_hash.slice("skip_studios", "skip_performers", "skip_lesbian")
    # end

    def override_urls
      {
        "all_scenes" => override_all_movies,
        "performers" => override_performers,
        "movies" => override_movies,
        "scenes" => override_scenes
      }.compact
    end

    def override_value(original, override)
      override.nil? ? original : override
    end

    def override_performers
      @override_performers ||= AdultTimeDL::FileUtils.read_yaml(options["performers"], nil, Array)
    end

    def override_movies
      @override_movies ||= AdultTimeDL::FileUtils.read_yaml(options["movies"], nil, Array)
    end

    def override_all_movies
      @override_all_movies ||= AdultTimeDL::FileUtils.read_yaml(options["all_scenes"], nil, Array)
    end

    def override_scenes
      @override_scenes ||= AdultTimeDL::FileUtils.read_yaml(options["all_scenes"], nil, Array)
    end

    attr_reader :site, :options

    def save_default_config
      AdultTimeDL.logger.info "-" * 100
      AdultTimeDL.logger.info "Config option not passed to app and no config file detected in the current directory."
      AdultTimeDL.logger.info "Generating a blank configuration file to #{DEFAULT_CONFIG_FILE} This app will now exit."
      AdultTimeDL.logger.info "Check the contents of the file and run the app again to start downloading."
      AdultTimeDL.logger.info "-" * 100

      if File.file?(DEFAULT_CONFIG_FILE) && File.exist?(DEFAULT_CONFIG_FILE)
        raise FatalError, "config file already exists"
      end

      File.open(DEFAULT_CONFIG_FILE, "w") do |file|
        file.write DEFAULT_CONFIG.to_yaml
      end
    end
  end
end
