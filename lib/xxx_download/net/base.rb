# frozen_string_literal: true

require "net/protocol"
require "openssl"

module XXXDownload
  module Net
    class Base
      include Utils
      include HTTParty

      def initialize
        self.class.logger XXXDownload.logger, :debug
        self.class.headers(default_headers)
      end

      #
      # @param [Boolean] return_raw returns the raw {HTTParty::Response} object if set to true,
      #                  otherwise the parsed response
      # @param [Proc] block a block which runs the HTTParty request
      # @return [HTTParty::Response]
      # @raise [XXXDownload::APIError]
      def handle_response!(return_raw: false, &block)
        handle_response_with_retry!(return_raw:, &block)
      end

      private

      ERROR_CODE_MAP = {
        302 => RedirectedError,
        400 => BadRequestError,
        401 => UnauthorizedError,
        403 => ForbiddenError,
        404 => NotFoundError,
        429 => TooManyRequestsError,
        500 => InternalServerError,
        503 => BadGatewayError
      }.freeze

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      # @param [Boolean] return_raw Set this to true if the response is JSON, and false for HTML
      # @param [Integer] current_attempt
      # @param [Integer] max_attempts
      # @param [Proc] block
      # @return [HTTParty::Response]
      # @raise [XXXDownload::APIError]
      def handle_response_with_retry!(return_raw: false, current_attempt: 1, max_attempts: 5, &block)
        raise ArgumentError, "expected HTTParty::Response or Proc, invoked with nil" unless block

        response = block.call

        if response.code == 200
          return return_raw ? response : response.parsed_response
        end

        error_klass = ERROR_CODE_MAP.fetch(response.code, UnhandledError)
        raise api_error(error_klass, response)
      rescue *RETRIABLE_ERRORS => e
        raise e if current_attempt > max_attempts

        if e.instance_of?(TooManyRequestsError)
          run_sleep(30, 6, e)
        elsif e.instance_of?(SocketError)
          # Try in rapid succession to check if network is back up
          run_sleep(5, 15, e)
        else
          XXXDownload.logger.error "[#{exception.class}] #{exception.message}"
        end

        handle_response_with_retry!(return_raw:,
                                    current_attempt: current_attempt + 1,
                                    max_attempts:,
                                    &block)
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def default_headers
        {
          "User-Agent" => "Mozilla/5.0 (Windows NT x.y; rv:10.0) Gecko/20100101 Firefox/10.0",
          "Accept" => "application/json",
          "DNT" => "1",
          "Connection" => "keep-alive"
        }
      end

      RETRIABLE_ERRORS = [
        SocketError,
        ::Net::OpenTimeout,
        ::Net::ReadTimeout,
        ::OpenSSL::SSL::SSLError,
        XXXDownload::TooManyRequestsError
      ].freeze

      # @param [Class<XXXDownload::APIError>] klass
      # @param [HTTParty::Response] response
      # @return [XXXDownload::APIError]
      def api_error(klass, response)
        endpoint = "#{response.request.base_uri}#{response.request.path}"
        klass.new(endpoint:, code: response.code,
                  body: response.parsed_response, headers: response.headers)
      end

      def config
        XXXDownload.config
      end

      # @param [Integer] sleep_duration
      # @param [Integer] counter
      # @param [Exception] exception
      def run_sleep(sleep_duration, counter, exception)
        XXXDownload.logger.error "[#{exception.class}] #{exception.message}"
        XXXDownload.logger.error "Going to sleep for #{counter * sleep_duration} seconds. " \
                                   "Cancel to run the app at a different time."
        counter.times do |c|
          sleep(sleep_duration)
          XXXDownload.logger.info "[SLEEP ELAPSED] #{c * sleep_duration}s"
        end
      end
    end
  end
end
