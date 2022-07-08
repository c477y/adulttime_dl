# frozen_string_literal: true

module AdultTimeDL
  class Client
    attr_reader :config

    # @param [Data::Config] config
    def initialize(config)
      @config = config
      config.validate_downloader!
      download_status_store
    end

    def start!
      AdultTimeDL.logger.info "[PROCESS START]"
      process_performer_file
      process_movies_file
      AdultTimeDL.logger.info "[PROCESS COMPLETE]"
    end

    private

    def process_movies_file
      config.movies.map do |movie|
        AdultTimeDL.logger.info "[PROCESSING URL] #{movie}".colorize(:cyan)
        scenes = Processor::MovieProcessor.new(scenes_index, movie).scenes
        Parallel.map(scenes, in_threads: config.parallel) { |scene_data| downloader.download(scene_data) }
      end
    end

    def process_performer_file
      config.performers.map do |performer|
        AdultTimeDL.logger.info "[PROCESSING URL] #{performer}".colorize(:cyan)
        scenes = Processor::PerformerProcessor.new(scenes_index, performer).scenes
        Parallel.map(scenes, in_threads: config.parallel) { |scene_data| downloader.download(scene_data) }
      end
    end

    def downloader
      @downloader ||= Downloader::Download.new(store: download_status_store,
                                               config: config,
                                               semaphore: semaphore)
    end

    def scenes_index
      @scenes_index ||= config.scenes_index
    end

    def semaphore
      @semaphore ||= Mutex.new
    end

    def download_status_store
      @download_status_store ||= Data::DownloadStatusDatabase.new(config.store, semaphore)
    end
  end
end
