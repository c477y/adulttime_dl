# frozen_string_literal: true

module AdultTimeDL
  module Downloader
    class GoodPornCommand
      def self.build(config, scene_data, url)
        CommandBuilder.new
                      .with_download_client(config.downloader)
                      .with_path(scene_data.file_name, config.download_dir, "mp4")
                      .with_external_flags(config.downloader_flags)
                      .with_url(url).build
      end
    end
  end
end

