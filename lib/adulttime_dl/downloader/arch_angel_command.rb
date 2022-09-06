# frozen_string_literal: true

module AdultTimeDL
  module Downloader
    class ArchAngelCommand
      def self.build(config, scene_data, url)
        CommandBuilder.new
                      .with_download_client(config.downloader)
                      .with_path(scene_data.file_name, config.download_dir)
                      .with_cookie(config.cookie_file, true)
                      .with_verbosity(config.verbose)
                      .with_url(url).build
      end
    end
  end
end

