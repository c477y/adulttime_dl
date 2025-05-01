# frozen_string_literal: true

module XXXDownload
  module Utils
    def valid_file?(file)
      file && File.file?(file) && File.exist?(file)
    end

    def valid_dir?(dir)
      dir && File.directory?(dir)
    end

    #
    # Extracts the base hostname (scheme + host) from a URL
    #
    # @param [String, URI] url The URL to parse
    # @return [String] The hostname in format "scheme://host"
    # @raise [ArgumentError] If the URL is nil or empty
    # @raise [URI::InvalidURIError] If the URL is invalid
    def hostname(url)
      raise ArgumentError, "URL cannot be nil or empty" if url.nil? || url.to_s.empty?

      uri = url.is_a?(URI) ? url : URI.parse(url.to_s)
      raise URI::InvalidURIError, "Invalid URL: missing scheme or host" if uri.scheme.nil? || uri.host.nil?

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
