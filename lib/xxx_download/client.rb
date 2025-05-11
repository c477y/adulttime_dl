# frozen_string_literal: true

module XXXDownload
  class Client
    def initialize
      download_status_store

      HTTParty::Logger.add_formatter("custom", Net::HttpCustomLogger)
    end

    def start!
      @exception = nil
      XXXDownload.logger.info "[PROCESS START]"
      XXXDownload.logger.debug "[PARALLEL DOWNLOAD(s)] #{config.parallel}"
      process_performer
      process_movies
      process_scenes
      process_page
      XXXDownload.logger.info "[PROCESS COMPLETE]"
    rescue StandardError => e
      @exception = e
      raise e
    ensure
      cleanup_index
    end

    private

    def process_movies
      config.movies.map do |url|
        XXXDownload.logger.info "[PROCESSING URL] #{url}".colorize(:cyan)
        scenes = scenes_index.search_by_movie(url)
        scenes.each { |x| XXXDownload.logger.ap x.to_h, :extra }
        Parallel.map(scenes, in_threads: config.parallel) do |scene_data|
          downloader.download(scene_data, scenes_index)
        end
      end
    end

    def process_performer
      config.performers.map do |entity|
        XXXDownload.logger.info "[PROCESSING ENTITY] #{entity}".colorize(:cyan)
        current_path = Dir.pwd
        sub_dir = create_sub_directory(dir_name(entity))
        scenes = scenes_index.search_by_actor(entity)
        scenes.each { |x| XXXDownload.logger.ap x.to_h, :extra }
        XXXDownload.logger.trace "[CHANGING DIRECTORY] #{sub_dir}"

        # putting this chdir in a block raises a runtime error
        # because the downloader also has a chdir block
        # @see {XXXDownload::Downloader::Download#file_downloaded?}
        Dir.chdir(sub_dir)
        Parallel.map(scenes, in_threads: config.parallel) do |scene_data|
          downloader.download(scene_data, scenes_index)
        end
        Dir.chdir(current_path)
        Dir.rmdir(sub_dir) if sub_dir.present? && Dir.empty?(sub_dir)
      end
    end

    def process_scenes
      config.scenes.map do |url|
        XXXDownload.logger.info "[PROCESSING URL] #{url}".colorize(:cyan)
        scenes = scenes_index.search_by_all_scenes(url)
        scenes.each { |x| XXXDownload.logger.ap x.to_h, :extra }
        Parallel.map(scenes, in_threads: 5) { |scene_data| downloader.download(scene_data, scenes_index) }
      end
    end

    def process_page
      config.page.map do |url|
        XXXDownload.logger.info "[PROCESSING URL] #{url}".colorize(:cyan)
        scenes = scenes_index.search_by_page(url)
        scenes.each { |x| XXXDownload.logger.ap x.to_h, :extra }
        Parallel.map(scenes, in_threads: config.parallel) { |scene_data| downloader.download(scene_data, scenes_index) }
      end
    end

    def cleanup_index
      XXXDownload.logger.error "[PROCESS ERROR] #{@exception.message}".colorize(:red) if @exception.present?
      scenes_index.cleanup
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

    def downloader            = @downloader ||= Downloader::Download.new(store: download_status_store, semaphore:)
    def scenes_index          = @scenes_index ||= config.scenes_index
    def semaphore             = @semaphore ||= Mutex.new
    def download_status_store = @download_status_store ||= Data::DownloadStatusDatabase.new(config.store, semaphore)
    def config                = XXXDownload.config
  end
end
