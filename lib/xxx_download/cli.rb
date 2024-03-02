# frozen_string_literal: true

module XXXDownload
  class CLI < Thor
    class StoreSubCommand < Thor
      desc "export", "Exports a datastore file to a yaml file"
      option :store, desc: "Path to the .store file to export"

      def export
        XXXDownload.logger(verbose: options["verbose"])
        Store.export(options["store"])
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
      Acceptable _site_ names: #{Data::Config::MODULE_NAME.keys.join(", ")}
    LONGDESC
    option :help, alias: :h, type: :boolean, default: false
    option :cookie_file, desc: "Path to the file where the cookie is stored"
    option :downloader, desc: "Name of the client to use to download. Can be either 'youtube-dl'(default) or 'yt-dlp'"
    option :store, desc: "Path to the .store file which tracks which files have been downloaded. " \
      "If not provided, a store file will be created by the CLI"
    option :parallel, type: :numeric, default: 1, aliases: :p, desc: "Number of parallel downloads to perform. " \
      "For optimal performance, do not set this to more than 5"
    option :config, aliases: :c, default: "config.yml", desc: "Path to YAML file with download filters " \
      "Defaults to config.yml in the current directory"
    option :verbose, type: :boolean, default: false, aliases: :v, desc: "Flag to print verbose logs. " \
      "Useful for debugging"
    def download(site)
      perform_with_error_handling do
        XXXDownload.logger(verbose: options["verbose"])
        XXXDownload.file_logger
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
    def perform_with_error_handling(&block)
      block.call
    rescue Interrupt
      say "Exiting...", :green
      exit 1
    rescue SafeExit
      exit 0
    rescue StandardError, FatalError => e
      XXXDownload.logger.fatal "#{e.class} - #{e.message}"
      XXXDownload.logger.debug "\t#{e.backtrace&.join("\n\t")}"
      exit 1
    end
  end
end
