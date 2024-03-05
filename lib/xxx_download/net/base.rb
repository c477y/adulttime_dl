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
      def handle_response!(return_raw:, &block)
        handle_response_with_retry!(return_raw:, &block)
      end

      private

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def handle_response_with_retry!(return_raw: false, current_attempt: 1, max_attempts: 5, &block)
        raise ArgumentError, "expected HTTParty::Response or Proc, invoked with nil" unless block

        response = block.call

        case response.code
        when 200 then return_raw ? response : response.parsed_response
        when 302 then raise api_error(RedirectedError, response)
        when 400 then raise api_error(BadRequestError, response)
        when 401 then raise api_error(UnauthorizedError, response)
        when 403 then raise api_error(ForbiddenError, response)
        when 429 then raise api_error(TooManyRequestsError, response)
        when 404 then raise api_error(NotFoundError, response)
        when 500 then raise api_error(InternalServerError, response)
        when 503 then raise api_error(BadGatewayError, response)
        else raise api_error(UnhandledError, response)
        end
      rescue *RETRIABLE_ERRORS => e
        raise e if current_attempt > max_attempts

        if e.instance_of?(TooManyRequestsError)
          XXXDownload.logger.error "[RATE LIMIT EXCEEDED] Sleeping for 3 minutes. "\
                                     "Cancel to run the app at a different time."
          6.times do |counter|
            sleep(30)
            XXXDownload.logger.info "[SLEEP ELAPSED] #{counter * 30}s"
          end
        else
          XXXDownload.logger.error "#{e.class}: message:#{e.message}"
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
    end
  end
end
