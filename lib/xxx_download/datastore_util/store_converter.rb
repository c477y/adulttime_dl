# frozen_string_literal: true

require "pstore"
require "yaml/store"
require "progressbar"

module XXXDownload
  module DatastoreUtil
    # Takes a datastore file of type {YAML::Store} or {PStore}
    # and interconverts it to the other type.
    class StoreConverter
      include Utils

      # @param [String] file
      def initialize(file)
        @file = file
        raise FatalError, "File #{file} does not exist" unless valid_file?(file)
      end

      # Exports the PStore datastore file to a YAML::Store file
      # @return [String] the new filename
      def export
        if yaml?
          XXXDownload.logger.info "[INVALID FILE TYPE DETECTED] Datastore file is already in YAML format."
          return file
        end

        raise FatalError, "Datastore file is not a valid PStore file." unless pstore?

        new_file = new_filename("yml")
        store = pstore
        new_store = YAML::Store.new(new_file)
        XXXDownload.logger.info "[CONVERT] Exporting #{file} to #{new_file}"
        store.transaction do
          new_store.transaction do
            progressbar = ProgressBar.create(title: "Export Progress", total: store.roots.length)
            store.roots.each do |key|
              progressbar.increment
              new_store[key] = store[key]
            end
          end
        end
        XXXDownload.logger.info "[PROCESS COMPLETED]"
        new_file
      end

      def import
        if pstore?
          XXXDownload.logger.info "[INVALID FILE TYPE DETECTED] Datastore file is already in PStore format."
          return file
        end

        raise FatalError, "Datastore file is not a valid YAML file." unless yaml?

        new_file = new_filename("pstore")
        store = yaml
        new_store = PStore.new(new_file)
        XXXDownload.logger.info "[CONVERT] Exporting #{file} to #{new_file}"
        store.transaction do
          new_store.transaction do
            progressbar = ProgressBar.create(title: "Import Progress", total: store.roots.length)
            store.roots.each do |key|
              progressbar.increment
              new_store[key] = store[key]
            end
          end
        end
        XXXDownload.logger.info "[PROCESS COMPLETED]"
        new_file
      end

      private

      attr_reader :file

      def pstore?
        store = pstore
        store.transaction { store.roots }
        true
      rescue TypeError => e
        XXXDownload.logger.debug "[PSTORE READ ERROR] #{e.message}"
        false
      end

      def pstore
        @pstore ||= PStore.new(file)
      end

      def yaml?
        store = yaml
        store.transaction { store.roots }
        true
      rescue Psych::SyntaxError, PStore::Error => e
        XXXDownload.logger.debug "[YAML READ ERROR] #{e.message}"
        false
      end

      def yaml
        @yaml ||= YAML::Store.new(file)
      end

      # @param [String] type One of "pstore" or "yml"
      # @return [String]
      def new_filename(type)
        "#{File.basename(file, File.extname(file))}_#{Time.now.strftime("%Y%d%m%H%M%S")}.store.#{type}"
      end
    end
  end
end
