# frozen_string_literal: true

require "net/protocol"
require "openssl"

module XXXDownload
  module Net
    class Base
      include Utils
      include HTTParty

      DEFAULT_HEADERS = {
        "User-Agent" => "Mozilla/5.0 (Windows NT x.y; rv:10.0) Gecko/20100101 Firefox/10.0",
        "Accept" => "application/json",
        "DNT" => "1",
        "Connection" => "keep-alive"
      }.freeze

      headers DEFAULT_HEADERS

      def initialize
        self.class.logger ::XXXDownload.logger, :trace
      end

      #
      # @param [Boolean] return_raw returns the raw {HTTParty::Response} object if set to true,
      #                  otherwise the parsed response
      # @param [Proc] block a block which runs the HTTParty request
      # @return [HTTParty::Response]
      # @raise [XXXDownload::APIError]
      def handle_response!(return_raw: false, handle_errors: true, &block)
        handle_response_with_retry!(return_raw:, handle_errors:, &block)
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
      # @param [Boolean] handle_errors Return the complete response object after making the call
      # @param [Integer] current_attempt
      # @param [Integer] max_attempts
      # @param [Proc] block
      # @return [HTTParty::Response]
      # @raise [XXXDownload::APIError]
      def handle_response_with_retry!(return_raw:, handle_errors:, current_attempt: 1, max_attempts: 5, &block)
        raise ArgumentError, "expected HTTParty::Response or Proc, invoked with nil" unless block

        response = block.call

        # Log all output to file for debugging
        # Tag all log entities with an ID because the file is written to
        # by multiple threads
        id = SecureRandom.uuid
        XXXDownload.logger.debug "[RESPONSE RECORDED #{id}] " \
                                 "#{response.request.http_method::METHOD} #{response.request.path}"
        XXXDownload.file_logger.info "#{id} START HTTP LOG"
        XXXDownload.file_logger.info "#{id} REQUEST URL:      #{response.request.http_method} #{response.request.path}"
        XXXDownload.file_logger.info "#{id} REQUEST HEADERS:  #{response.request.options[:headers]}"
        XXXDownload.file_logger.info "#{id} REQUEST BODY:     #{response.request.options[:body]}"

        XXXDownload.file_logger.info "#{id} RESPONSE HEADERS: #{response.headers}"
        XXXDownload.file_logger.info "#{id} RESPONSE BODY:    #{response.body}"
        XXXDownload.file_logger.info "#{id} END HTTP LOG"

        return response unless handle_errors

        if response.code == 200
          return return_raw ? response : response.parsed_response
        end

        handle_api_error(response)
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
                                    handle_errors:,
                                    current_attempt: current_attempt + 1,
                                    max_attempts:,
                                    &block)
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      # @param [HTTParty::Response]
      # @raise [XXXDownload::APIError]
      def handle_api_error(response)
        error_klass = ERROR_CODE_MAP.fetch(response.code, UnhandledError)
        raise api_error(error_klass, response)
      end

      def default_headers
        DEFAULT_HEADERS
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
