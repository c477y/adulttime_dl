# frozen_string_literal: true

require "yaml/store"

module AdultTimeDL
  module Data
    class DownloadStatusDatabase
      attr_reader :store, :semaphore

      def initialize(store_file, semaphore)
        path = File.join(Dir.pwd, store_file)
        AdultTimeDL.logger.info "[DATABASE_INIT] #{path}"

        @store = YAML::Store.new path
        @semaphore = semaphore
      end

      def downloaded?(key)
        semaphore.synchronize do
          store.transaction(true) do
            scene_data = store.fetch(key, nil)
            return true if scene_data&.downloaded?
          end
          false
        end
      end

      def save_download(scene_data, is_downloaded: false)
        semaphore.synchronize do
          AdultTimeDL.logger.debug "[DATABASE_ADD] #{scene_data.file_name} : #{is_downloaded}"
          store.transaction do
            new_scene_data = scene_data.mark_downloaded(is_downloaded)
            store[new_scene_data.key] = new_scene_data
          end
        end
      end
    end
  end
end
