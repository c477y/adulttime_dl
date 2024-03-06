# frozen_string_literal: true

module XXXDownload
  class Client
    def initialize
      download_status_store
    end

    def start!
      XXXDownload.logger.info "[PROCESS START]"
      process_performer
      process_movies
      process_scenes
      XXXDownload.logger.info "[PROCESS COMPLETE]"
    end

    private

    def process_movies
      config.movies.map do |url|
        XXXDownload.logger.info "[PROCESSING URL] #{url}".colorize(:cyan)
        scenes = scenes_index.search_by_movie(url)
        Parallel.map(scenes, in_threads: config.parallel) { |scene_data| downloader.download(scene_data, generator) }
      end
    end

    def process_performer
      config.performers.map do |entity|
        XXXDownload.logger.info "[PROCESSING ENTITY] #{entity}".colorize(:cyan)
        dir_name = dir_name(entity).presence
        path = if dir_name.present?
                 Dir.mkdir(dir_name) unless Dir.exist?(dir_name)
                 File.join(Dir.pwd, dir_name)
               else
                 Dir.pwd
               end
        scenes = scenes_index.search_by_actor(entity)
        XXXDownload.logger.trace "[CHANGING DIRECTORY] #{path}"
        Dir.chdir(path) do
          Parallel.map(scenes, in_threads: config.parallel) { |scene_data| downloader.download(scene_data, generator) }
        end

        Dir.rmdir(dir_name) if dir_name.present? && Dir.empty?(dir_name)
      end
    end

    def process_scenes
      config.scenes.map do |url|
        XXXDownload.logger.info "[PROCESSING URL] #{url}".colorize(:cyan)
        scenes = scenes_index.search_by_all_scenes(url)
        Parallel.map(scenes, in_threads: config.parallel) { |scene_data| downloader.download(scene_data, generator) }
      end
    end

    def dir_name(url)
      scenes_index.actor_name(url).presence
    rescue NotImplementedError => e
      XXXDownload.logger.warn e.message
      nil
    end

    def downloader
      @downloader ||= Downloader::Download.new(store: download_status_store, semaphore:)
    end

    def scenes_index
      @scenes_index ||= config.scenes_index
    end

    def generator
      proc { |s, u| scenes_index.command(s, u) }
    end

    def semaphore
      @semaphore ||= Mutex.new
    end

    def download_status_store
      @download_status_store ||= Data::DownloadStatusDatabase.new(config.store, semaphore)
    end

    def config
      XXXDownload.config
    end
  end
end
