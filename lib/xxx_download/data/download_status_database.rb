# frozen_string_literal: true

require "yaml/store"

module XXXDownload
  module Data
    class DownloadStatusDatabase
      attr_reader :store, :semaphore

      def initialize(store_file, semaphore)
        path = File.join(Dir.pwd, store_file)
        XXXDownload.logger.info "[DATABASE_INIT] #{path}"

        @store = PStore.new(path)
        @semaphore = semaphore
      end

      # @param key [String] The key to check in the database.
      # @return [Boolean] Returns true if the key is present in the database, false otherwise.
      def downloaded?(key)
        benchmark("downloaded?") do
          semaphore.synchronize do
            store.transaction(true) do
              scene_data = store.fetch(key, nil)
              return scene_data.present?
            end
          end
        end
        false
      end

      # @param scene_data [XXXDownload::Data::Scene] The data of the scene to be stored in the database.
      # @return [Boolean] Returns true after successfully storing the scene data.
      def save_download(scene_data)
        benchmark("save_download") do
          semaphore.synchronize do
            XXXDownload.logger.trace "[ADDING TO STORE] #{scene_data.file_name}"
            store.transaction do
              store[scene_data.key] = scene_data
            end
          end
        end
        true
      end

      def inspect
        "[#{self.class.name}] #{store.path}"
      end

      private

      def benchmark(opr = "unnamed")
        raise "#benchmark called without block" unless block_given?

        resp = nil
        time = Benchmark.measure { resp = yield }
        XXXDownload.logger.extra "[BENCHMARK] #{self.class.name}##{opr}: #{time.real.round(3)}s"
        resp
      end
    end
  end
end
