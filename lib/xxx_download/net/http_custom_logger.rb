# frozen_string_literal: true

module XXXDownload
  module Net
    class HttpCustomLogger
      TAG_NAME = HTTParty.name

      attr_accessor :level, :logger

      def initialize(logger, level)
        @logger = logger
        @level  = level.to_sym
      end

      def format(request, response)
        @request = request
        @response = response

        logger.public_send level, message
      end

      private

      attr_reader :request, :response

      def message
        msg = "[#{TAG_NAME}] #{current_time}\n" \
              "\t REQUEST: #{http_method} #{full_path}\n" \
              "\t RESPONSE: CODE [#{response.code}] CONTENT_LENGTH [#{content_length}] CONTENT_TYPE [#{content_type}]"
        msg << "\n\t           LOCATION[#{redirect_location}]" if redirected?
        msg
      end

      def current_time      = Time.now.strftime("%Y-%m-%d %H:%M:%S %z")
      def http_method       = request.http_method.name.split("::").last.upcase
      def full_path         = request.uri.to_s
      def content_length    = header_value("Content-Length")
      def content_type      = header_value("Content-Type")
      def redirect_location = header_value("Location")
      def redirected?       = response.code.to_i > 300 && response.code.to_i < 400

      def header_value(key, fallback = "-")
        val = response.respond_to?(:headers) ? response.headers[key] : response[key]
        val || fallback
      end
    end
  end
end
