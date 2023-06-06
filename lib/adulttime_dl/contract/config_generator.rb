# frozen_string_literal: true

module Contract
  class ConfigGenerator
    include AdultTimeDL::Utils

    DEFAULT_CONFIG = {
      c00: "[List] Skip studios based on name",
      c01: "If any scene belongs to that studio, the scene will be skipped",
      "skip_studios" => [],
      c02: "[List] Skip performers based on name",
      "skip_performers" => [],
      c03: "[Boolean] Skip downloading scenes with only female actors",
      c04: "This only works with certain sites that provide gender information for performers",
      "skip_lesbian" => false,
      c05: "[String] Path to a cookie file. Used only for sites that require membership",
      c06: "information. Use a browser extension to get a cookie file",
      c07: "If you are on mozilla, you can use https://addons.mozilla.org/en-GB/firefox/addon/cookies-txt/",
      "cookie_file" => "cookies.txt",
      c08: "[String] Name of file that tracks list of downloaded scenes",
      "store" => "adt_download_status.store",
      c09: "[String] Name of downloader tool to use. Currently supports youtube-dl",
      c10: "and yt-dlp",
      c11: "Ensure that the downloader is available in your $PATH",
      "downloader" => "youtube-dl",
      c12: "[String] Directory to download scenes. '.' means current directory",
      "download_dir" => ".",
      c13: "[String] Resolution of scene to download. Accepts one of 'sd', 'hd', and 'fhd'",
      "quality" => "hd",
      c14: "[Number] Number of parallel download jobs",
      "parallel" => 1,
      c15: "[Boolean] Enable/Disable verbose logging",
      "verbose" => false,
      c16: "[Boolean] Just log to console, doesn't download anything",
      "dry_run" => false,
      c17: "[String] Arguments to pass to external downloader",
      c18: "Check the documentation of youtube-dl or yt-dlp for details",
      "downloader_flags" => "",
      "urls" => {
        c00: "[List] URLs of performer names that will be downloaded",
        "performers" => [],
        c01: "[List] URLs of movie names that will be downloaded",
        "movies" => [],
        c02: "[List] URLs of scene names that will be downloaded",
        "scenes" => []
      },
      c19: "[OPTIONAL] These are site specific configuration only needed for some sites",
      "site_config" => {
        "blowpass" => {
          c00: "Get Algolia credentials from Web Console",
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

    def override_urls
      {
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

    def override_scenes
      @override_scenes ||= AdultTimeDL::FileUtils.read_yaml(options["scenes"], nil, Array)
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
        YAML.dump(DEFAULT_CONFIG).each_line do |l|
          if l.match(/:c(\d+)?:/)
            # Removes hash key(c00) from the string
            # Adds a # in front of the string
            l.sub!(/:c(\d+)?:/, "#")
            # Removes " from the beginning of the line
            l.sub!(/(^\s*# )["']/, '\1')
            # Removes " from the end of the line
            l.sub!(/["']\s*$/, "")
          end
          file.puts l
        end
      end
    end
  end
end
