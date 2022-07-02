# frozen_string_literal: true

require "forwardable"

module AdultTimeDL
  class Client
    extend Forwardable

    attr_reader :config

    # @param [Data::Config] config
    def initialize(config)
      AdultTimeDL.logger(verbose: config.verbose)
      @config = config
      config.validate_downloader!
      config.blacklisted_studios
    end

    def start!
      AdultTimeDL.logger.info "[PROCESS START]"
      config.validate_downloader!
      process_performer_file

      AdultTimeDL.logger.info "[PROCESS COMPLETE]"
    end

    private

    def process_performer_file
      performers = config.load_performers!
      performers.map do |performer|
        AdultTimeDL.logger.info "[PROCESSING URL] #{performer}"
        scenes = Processor::PerformerProcessor.new(scenes_index, performer).scenes
        Parallel.map(scenes, in_threads: config.parallel) { |scene_data| downloader.download(scene_data, link_fetcher) }
      end
    end

    def downloader
      @downloader ||= Downloader::Download.new(store: download_status_store,
                                               config: config)
    end

    def scenes_index
      @scenes_index ||= Net::ScenesIndex.new
    end

    def link_fetcher
      @link_fetcher ||= Net::StreamingLinks.new(config.cookie!)
    end

    def semaphore
      @semaphore ||= Mutex.new
    end

    def download_status_store
      @download_status_store ||= Data::DownloadStatusDatabase.new(config.store, semaphore)
    end
  end
end
