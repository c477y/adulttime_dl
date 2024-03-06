# frozen_string_literal: true

module XXXDownload
  class Cli < Thor
    LOG_LEVELS = %w[extra trace debug info warn error fatal].freeze

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
      Acceptable _site_ names: #{XXXDownload::Data::Config::MODULE_NAME.keys.join(", ")}
    LONGDESC
    option :help, alias: :h, type: :boolean, default: false
    option :cookie_file, desc: "Path to the file where the cookie is stored"
    option :downloader, desc: "Name of the client to use to download. Can be either 'youtube-dl'(default) or 'yt-dlp'"
    option :store, desc: "Path to the .store file which tracks which files have been downloaded. " \
      "If not provided, a store file will be created by the CLI"
    option :parallel, type: :numeric, default: 1, aliases: :p, desc: "Number of parallel downloads to perform. " \
      "For optimal performance, do not set this to more than 5"
    option :log_level, type: :string, enum: LOG_LEVELS,
                       default: "info", desc: "Log level. Can be one of #{LOG_LEVELS.join(", ")}"
    def download(site)
      perform_with_error_handling do
        XXXDownload.set_logger(options["log_level"])
        config = Contract::ConfigGenerator.new(site, options).generate
        client = Client.new(config)
        client.start!
      end
    end

    # desc "generate", "Fetch the list of actors/movies from a site"
    # long_desc <<~LONGDESC
    #   Accepts a sitename and fetches all the actors or movies listed down in the site.
    # LONGDESC
    # option :cookie_file, default: "cookies.txt", aliases: :c, desc: "Path to the file where the cookie is stored"
    # option :verbose, type: :boolean, default: false, aliases: :v, desc: "Flag to print verbose logs"
    # def generate(site, object)
    #   XXXDownload.logger(verbose: options["verbose"])
    #   config = Data::GeneratorConfig.new({ site: site, object: object }.merge(options))
    #   GenerateClient.new(config).start!
    # rescue Interrupt
    #   say "Exiting...", :green
    # rescue SafeExit
    #   nil
    # rescue StandardError, FatalError => e
    #   XXXDownload.logger.fatal "#{e.class} - #{e.message}"
    #   XXXDownload.logger.debug "\t#{e.backtrace.join("\n\t")}"
    #   exit 1
    # end

    def self.perform_with_error_handling(&block)
      block.call
    rescue Interrupt
      say "Exiting...", :green
      exit 1
    rescue SafeExit => e
      XXXDownload.logger.info e.message
      exit 0
    rescue StandardError, FatalError => e
      XXXDownload.logger.fatal "#{e.class} - #{e.message}"
      XXXDownload.logger.debug "\t#{e.backtrace&.join("\n\t")}"
      exit 1
    end

    desc "store SUBCOMMAND ...ARGS", "Manage datastore files"
    subcommand "store", StoreSubCommand
  end
end
