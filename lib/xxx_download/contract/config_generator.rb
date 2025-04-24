# frozen_string_literal: true

module XXXDownload
  module Contract
    class ConfigGenerator
      include XXXDownload::Utils
      include Contract::Default

      def initialize(site, options)
        unless config_file_exists?
          save_default_config
          raise XXXDownload::SafeExit, "DEFAULT_FILE_GENERATION"
        end

        @site = site
        @options = options
      end

      def generate
        config_from_defaults = Default.cleaned_config
        config_with_file_overrides = hash_from_config_file.deeper_merge(config_from_defaults)
        merged_config = config_with_file_overrides.deeper_merge!(override_values)

        validated_config = validate_download_filters!(merged_config)
        config = XXXDownload::Data::Config.new(validated_config)
        XXXDownload.logger.ap config.to_h, :extra

        config
      end

      def hash_from_config_file
        @hash_from_config_file ||= XXXDownload::FileUtils.read_yaml(DEFAULT_CONFIG_FILE).merge("site" => site)
      end

      private

      def validate_download_filters!(hash)
        contract = Contract::DownloadFiltersContract.new.call(hash)
        unless contract.errors.empty?
          message = generate_error_message(contract.errors)
          raise XXXDownload::FatalError, "[INVALID DOWNLOAD FILTERS] #{message}"
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

      def override_values
        {}.tap do |h|
          h["cookie_file"] = options["cookie_file"] if options["cookie_file"].present?
          h["downloader"] = options["downloader"] if options["downloader"].present?
          h["parallel"] = options["parallel"] if options["parallel"].present?
          h["quality"] = options["quality"] if options["quality"].present?
          h["verbose"] = options["verbose"] if options["verbose"].present?
          h["headless"] = options["headless"]
        end
      end

      def override_value(original, override)
        override.nil? ? original : override
      end

      attr_reader :site, :options

      def save_default_config
        # rubocop:disable Layout/LineLength
        XXXDownload.logger.info "-" * 100
        XXXDownload.logger.info "Config option not passed to app and no config file detected in the current directory."
        XXXDownload.logger.info "Generating a blank configuration file to #{DEFAULT_CONFIG_FILE} This app will now exit."
        XXXDownload.logger.info "Check the contents of the file and run the app again to start downloading."
        XXXDownload.logger.info "-" * 100
        # rubocop:enable Layout/LineLength

        File.open(DEFAULT_CONFIG_FILE, "w") do |file|
          YAML.dump(DEFAULT_CONFIG, line_width: 500, stringify_names: true, canonical: false).each_line do |l|
            if l.match(/:c(\d+)?:/)
              # Removes hash key(c00) from the string
              # Adds a # in front of the string
              l.sub!(/:c(\d+)?:/, "#")
              # Removes " from the beginning of the line
              l.sub!(/(^\s*# )["']/, '\1')
              # Removes " from the end of the line
              l.sub!(/["']\s*$/, "")
            end

            l = "\n" if l.match(/:cn(\d)+:/)
            file.puts l
          end
        end
      end

      def config_file_exists?
        valid_file?(DEFAULT_CONFIG_FILE)
      end
    end
  end
end
