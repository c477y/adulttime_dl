# frozen_string_literal: true

module XXXDownload
  class Cli < Thor
    LOG_LEVELS = %w[extra trace debug info warn error fatal].freeze
    RETRIABLE_ERRORS = [
      "Net::ReadTimeout",
      "Selenium::WebDriver::Error::TimeoutError"
    ].freeze

    class StoreSubCommand < Thor
      desc "export datastore.store", "Exports a datastore file to a yaml file"
      option :log_level, type: :string, enum: LOG_LEVELS,
                         default: "info", desc: "Log level. Can be one of #{LOG_LEVELS.join(", ")}"
      def export(store)
        XXXDownload.set_logger(options["log_level"])
        DatastoreUtil::StoreConverter.new(store).export
      end

      desc "import datastore.store", "Imports a yaml file to a datastore file"
      option :log_level, type: :string, enum: LOG_LEVELS,
                         default: "info", desc: "Log level. Can be one of #{LOG_LEVELS.join(", ")}"
      def import(store)
        XXXDownload.set_logger(options["log_level"])
        Cli.perform_with_error_handling { DatastoreUtil::StoreConverter.new(store).import }
      end
    end

    def self.exit_on_failure?
      true
    end

    desc "version", "app version"
    def version
      require_relative "version"
      puts "v#{XXXDownload::VERSION}"
    end
    map %w[--version -v] => :version

    desc "download _site_", "Bulk download files"
    long_desc <<~LONGDESC
      Acceptable _site_ names: #{XXXDownload::Data::Config::MODULE_NAME.keys.sort.join(", ")}
    LONGDESC
    option :help, alias: :h, type: :boolean, default: false
    option :cookie_file, desc: "Path to the file where the cookie is stored"
    option :downloader, desc: "Name of the client to use to download. Can be either 'youtube-dl'(default) or 'yt-dlp'"
    option :store, desc: "Path to the .store file which tracks which files have been downloaded. " \
                         "If not provided, a store file will be created by the CLI"
    option :parallel, type: :numeric, default: 1, aliases: :N, desc: "Number of parallel downloads to perform. " \
                                                                     "For optimal performance, do not set this to " \
                                                                     "more than 5"
    option :log_level, type: :string, enum: LOG_LEVELS, aliases: :l,
                       default: "info", desc: "Log level. Can be one of #{LOG_LEVELS.join(", ")}"
    option :headless, type: :boolean, default: false, desc: "Use a headless browser to download the files"
    option :retry, type: :boolean, default: false, desc: "Retries the process on errors", hide: true
    def download(site = nil)
      exit_if_no_site!(site)

      Cli.perform_with_error_handling(rerun: options["retry"]) do
        XXXDownload.set_logger(options["log_level"])
        config = Contract::ConfigGenerator.new(site, options).generate
        XXXDownload.set_config(config)

        client = Client.new
        client.start!
      end
    end

    desc "generate _site_ _entity_", "Fetch the list of actors/movies from a site"
    long_desc <<~LONGDESC
      Accepts a sitename and fetches all the actors or movies listed down in the site.\n
      Acceptable _site_ names: #{XXXDownload::Data::GeneratorConfig::SUPPORTED_SITE.values.sort.join(", ")}.\n
      Acceptable _entity_ names: #{XXXDownload::Data::GeneratorConfig::OBJECT.values.sort.join(", ")}.
    LONGDESC
    option :log_level, type: :string, enum: LOG_LEVELS, aliases: :l,
                       default: "info", desc: "Log level. Can be one of #{LOG_LEVELS.join(", ")}"
    def generate(site, object)
      Cli.perform_with_error_handling do
        XXXDownload.set_logger(options["log_level"])
        config = Data::GeneratorConfig.new({ site:, object: })

        GenerateClient.new(config).start!
      end
    end

    def self.perform_with_error_handling(rerun: false, &block)
      block.call
    rescue Interrupt
      XXXDownload.logger.info "Exiting..."
      exit 1
    rescue SafeExit => e
      XXXDownload.logger.trace e.message
      exit 0
    rescue StandardError => e
      XXXDownload.logger.fatal "#{e.class} - #{e.message}"
      XXXDownload.logger.fatal "\t#{e.backtrace&.join("\n\t")}"
      exit 1 unless rerun

      XXXDownload.logger.debug "[PROCESS RETRY CHECK] #{e.class} - #{e.message}"
      return unless RETRIABLE_ERRORS.include?(e.class.name)

      XXXDownload.logger.info "[RETRYING DOWNLOAD PROCESS]"
      Dir.chdir(CURRENT_DIR)
      perform_with_error_handling(rerun:, &block)
    end

    no_commands do
      def exit_if_no_site!(site)
        return unless site.nil?

        puts "Specify a site to download from. " \
             "Supported sites: #{XXXDownload::Data::Config::MODULE_NAME.keys.sort.join(", ")}"
        exit 1
      end
    end

    desc "store SUBCOMMAND ...ARGS", "Manage datastore files"
    subcommand "store", StoreSubCommand
  end
end
