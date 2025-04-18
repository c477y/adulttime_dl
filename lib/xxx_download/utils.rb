# frozen_string_literal: true

module XXXDownload
  module Utils
    def valid_file?(file)
      file && File.file?(file) && File.exist?(file)
    end

    def valid_dir?(dir)
      dir && File.directory?(dir)
    end

    def hostname(url)
      uri = URI.parse(url)
      "#{uri.scheme}://#{uri.host}"
    end

    def parse_time(time_str, source_format)
      DateTime.strptime(time_str, source_format).strftime("%Y-%m-%d")
    rescue Date::Error => e
      XXXDownload.logger.warn "[#{TAG}] Error parsing time: #{time_str} with error #{e.message}"
      nil
    end
  end
end
