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
      process_page
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
        current_path = Dir.pwd
        sub_dir = create_sub_directory(dir_name(entity))

        scenes = scenes_index.search_by_actor(entity)
        if current_path == sub_dir
          Parallel.map(scenes, in_threads: config.parallel) { |scene_data| downloader.download(scene_data, generator) }
        else
          XXXDownload.logger.trace "[CHANGING DIRECTORY] #{sub_dir}"
          Dir.chdir(sub_dir)
          Parallel.map(scenes, in_threads: config.parallel) { |scene_data| downloader.download(scene_data, generator) }
          Dir.chdir(current_path)
        end

        Dir.rmdir(sub_dir) if sub_dir.present? && Dir.empty?(sub_dir)
      end
    end

    def process_scenes
      config.scenes.map do |url|
        XXXDownload.logger.info "[PROCESSING URL] #{url}".colorize(:cyan)
        scenes = scenes_index.search_by_all_scenes(url)
        Parallel.map(scenes, in_threads: 5) { |scene_data| downloader.download(scene_data, generator) }
      end
    end

    def process_page
      config.page.map do |url|
        XXXDownload.logger.info "[PROCESSING URL] #{url}".colorize(:cyan)
        scenes = scenes_index.search_by_page(url)
        Parallel.map(scenes, in_threads: config.parallel) { |scene_data| downloader.download(scene_data, generator) }
      end
    end

    def create_sub_directory(name)
      return Dir.pwd unless name.present?

      ::FileUtils.mkdir_p(name)
      File.join(Dir.pwd, name)
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
      proc { |s, u, st| scenes_index.command(s, u, st) }
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
