# frozen_string_literal: true

module AdultTimeDL
  class Client
    attr_reader :config

    # @param [Data::Config] config
    def initialize(config)
      @config = config
      download_status_store
    end

    def start!
      AdultTimeDL.logger.info "[PROCESS START]"
      process_performer
      process_movies
      process_all_scenes
      AdultTimeDL.logger.info "[PROCESS COMPLETE]"
    end

    private

    def process_movies
      config.movies.map do |url|
        AdultTimeDL.logger.info "[PROCESSING URL] #{url}".colorize(:cyan)
        scenes = scenes_index.search_by_movie(url)
        Parallel.map(scenes, in_threads: config.parallel) { |scene_data| downloader.download(scene_data) }
      end
    end

    def process_performer
      config.performers.map do |url|
        AdultTimeDL.logger.info "[PROCESSING URL] #{url}".colorize(:cyan)
        scenes = scenes_index.search_by_actor(url)
        Parallel.map(scenes, in_threads: config.parallel) { |scene_data| downloader.download(scene_data) }
      end
    end

    def process_all_scenes
      config.all_scenes.map do |url|
        AdultTimeDL.logger.info "[PROCESSING URL] #{url}".colorize(:cyan)
        scenes = scenes_index.search_by_all_scenes(url)
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
