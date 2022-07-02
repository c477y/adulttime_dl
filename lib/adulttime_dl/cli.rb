# frozen_string_literal: true

module AdultTimeDL
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "version", "app version"
    def version
      require_relative "version"
      puts "v#{ElegantAngelDL::VERSION}"
    end
    map %w[--version -v] => :version

    desc "download", "Bulk download files"
    long_desc <<~LONGDESC
      Download scenes from https://members.adulttime.com.
    LONGDESC
    option :help, alias: :h, type: :boolean, default: false
    option :cookie_file, required: false, desc: "Path to the file where the cookie is stored", aliases: :c
    option :downloader, required: false,
                        desc: "Name of the client to use to download. Can be either 'youtube-dl'(default) or 'yt-dlp'"
    option :download_dir, required: false, desc: "Directory where the files should be downloaded", aliases: :d
    option :store, required: false, desc: "Path to the .store file which tracks which files have been downloaded"
    option :performer_file, required: false, desc: "Path to a YAML file with list of pages of performers", aliases: :p
    option :parallel, required: false, type: :numeric, desc: "Number of parallel downloads to perform"
    option :quality, required: false, desc: "Quality of video to download. Allows 'sd', 'hd' or 'fhd'"
    option :verbose, type: :boolean, default: false, desc: "Flag to print verbose logs"
    option :skip_studios, required: false, desc: "List of studios to skip downloading"
    option :skip_lesbian, type: :boolean, default: false, desc: "Enable to skip downloading lesbian scenes"
    def download
      handle_help_option(:download)
      config = Data::Config.new(**options)
      client = Client.new(config)
      client.start!
    rescue Interrupt
      say "Exiting...", :green
    end

    private

    def handle_help_option(method_name)
      return unless options[:help]

      help(method_name)
      exit
    end
  end
end
