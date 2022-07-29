# frozen_string_literal: true

module AdultTimeDL
  class CLI < Thor
    include Utils

    def self.exit_on_failure?
      true
    end

    desc "version", "app version"
    def version
      require_relative "version"
      puts "v#{AdultTimeDL::VERSION}"
    end
    map %w[--version -v] => :version

    desc "download adulttime", "Bulk download files"
    long_desc <<~LONGDESC
      Acceptable site names: adulttime, ztod
      Download scenes from https://members.adulttime.com.
    LONGDESC
    option :help, alias: :h, type: :boolean, default: false
    option :cookie_file,
           required: false, aliases: :c,
           desc: "Path to the file where the cookie is stored"
    # option :netscape_cookie, required: false, desc: "Path to the file where the cookie is stored"
    option :downloader,
           required: false,
           desc: "Name of the client to use to download. Can be either 'youtube-dl'(default) or 'yt-dlp'"
    option :download_dir,
           required: false, default: ".",
           desc: "Directory where the files should be downloaded"
    option :store,
           required: false,
           desc: "Path to the .store file which tracks which files have been downloaded"
    option :performers,
           required: false, default: "performers.yml",
           desc: "Path to a YAML file with list of pages of performers"
    option :movies,
           required: false, default: "movies.yml",
           desc: "Path to a YAML file with list of pages of movies"
    option :parallel,
           required: false, type: :numeric, default: 1, aliases: :p,
           desc: "Number of parallel downloads to perform"
    option :quality,
           required: false,
           desc: "Quality of video to download. Allows 'sd', 'hd' or 'fhd'"
    option :download_filter,
           required: false, default: "config.yml",
           desc: "Path to YAML file with download filters"
    option :verbose, type: :boolean, default: false, aliases: :v, desc: "Flag to print verbose logs"
    def download(site)
      AdultTimeDL.logger(verbose: options["verbose"])
      handle_help_option(:download)
      download_filters = validate_download_filters!(options[:download_filter])
      override_hash = {
        "cookie_file" => options["cookie_file"],
        "performers_l" => FileUtils.read_yaml(options["performers"], [], Array),
        "movies_l" => FileUtils.read_yaml(options["movies"], [], Array)
      }.compact
      raw_config = download_filters.merge(**options.compact).merge(
        **override_hash,
        "download_filters_l" => download_filters.slice("skip_studios", "skip_performers", "skip_lesbian"),
        "site" => site
      )
      config = Data::Config.new(raw_config)
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

    private

    def handle_help_option(method_name)
      return unless options[:help]

      help(method_name)
      exit
    end
  end
end
