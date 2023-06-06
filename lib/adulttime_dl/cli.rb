# frozen_string_literal: true

module AdultTimeDL
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "version", "app version"
    def version
      require_relative "version"
      puts "v#{AdultTimeDL::VERSION}"
    end
    map %w[--version -v] => :version

    desc "download _site_", "Bulk download files"
    long_desc <<~LONGDESC
      Acceptable site names: adulttime, archangel, blowpass, goodporn, julesjordan, loveherfilms, manuelferrara, 
      pornve, scoregroup, sxyporn, ztod
    LONGDESC
    option :help, alias: :h, type: :boolean, default: false
    option :cookie_file, desc: "Path to the file where the cookie is stored"
    option :downloader, desc: "Name of the client to use to download. Can be either 'youtube-dl'(default) or 'yt-dlp'"
    option :download_dir, desc: "Directory where the files should be downloaded"
    option :store, desc: "Path to the .store file which tracks which files have been downloaded"
    option :parallel, type: :numeric, default: 1, aliases: :p, desc: "Number of parallel downloads to perform"
    option :quality, desc: "Quality of video to download. Allows 'sd', 'hd' or 'fhd'"
    option :config, aliases: :c, default: "config.yml", desc: "Path to YAML file with download filters"
    option :verbose, type: :boolean, default: false, aliases: :v, desc: "Flag to print verbose logs"
    def download(site)
      AdultTimeDL.logger(verbose: options["verbose"])
      config = Contract::ConfigGenerator.new(site, options).generate
      client = Client.new(config)
      client.start!
    rescue Interrupt
      say "Exiting...", :green
    rescue SafeExit
      nil
    rescue StandardError, FatalError => e
      AdultTimeDL.logger.fatal "#{e.class} - #{e.message}"
      AdultTimeDL.logger.debug "\t#{e.backtrace.join("\n\t")}"
      exit 1
    end

    desc "generate", "Fetch the list of actors/movies from a site"
    long_desc <<~LONGDESC
      Accepts a sitename and fetches all the actors or movies listed down in the site.
    LONGDESC
    option :cookie_file, default: "cookies.txt", aliases: :c, desc: "Path to the file where the cookie is stored"
    option :verbose, type: :boolean, default: false, aliases: :v, desc: "Flag to print verbose logs"
    def generate(site, object)
      AdultTimeDL.logger(verbose: options["verbose"])
      config = Data::GeneratorConfig.new({ site: site, object: object }.merge(options))
      GenerateClient.new(config).start!
    rescue Interrupt
      say "Exiting...", :green
    rescue SafeExit
      nil
    rescue StandardError, FatalError => e
      AdultTimeDL.logger.fatal "#{e.class} - #{e.message}"
      AdultTimeDL.logger.debug "\t#{e.backtrace.join("\n\t")}"
      exit 1
    end
  end
end
