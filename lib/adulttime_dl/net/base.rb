# frozen_string_literal: true

require "net/protocol"
require "openssl"

module AdultTimeDL
  module Net
    class Base
      include Utils

      def default_headers
        {
          "User-Agent" => "Mozilla/5.0 (Windows NT x.y; rv:10.0) Gecko/20100101 Firefox/10.0",
          "Accept" => "application/json",
          "DNT" => "1"
        }
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      # @param [HTTParty::Response] response
      def handle_response!(response, return_raw: false)
        case response.code
        when 200 then return_raw ? response : response.parsed_response
        when 302 then raise api_error(RedirectedError, response)
        when 400 then raise api_error(BadRequestError, response)
        when 401 then raise api_error(UnauthorizedError, response)
        when 403 then raise api_error(ForbiddenError, response)
        when 404 then raise api_error(NotFoundError, response)
        when 500 then raise api_error(BadGatewayError, response)
        else raise api_error(UnhandledError, response)
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      RETRIABLE_ERRORS = [
        ::Net::OpenTimeout,
        ::Net::ReadTimeout,
        ::OpenSSL::SSL::SSLError,
        TooManyRequestsError
      ].freeze

      # rubocop:disable Metrics/CyclomaticComplexity
      def handle_response_v2!(return_raw: false, current_attempt: 1, max_attempts: 5, &block)
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
          AdultTimeDL.logger.error "[RATE LIMIT EXCEEDED] Sleeping for 3 minutes. "\
                                   "Cancel to run the app at a different time."
          6.times do |counter|
            sleep(30)
            AdultTimeDL.logger.info "[SLEEP ELAPSED] #{counter * 30}s"
          end
        else
          AdultTimeDL.logger.error "#{e.class}: message:#{e.message}"
        end
        handle_response_v2!(return_raw: return_raw, current_attempt: current_attempt + 1, max_attempts: max_attempts,
&block)
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      private

      # @param [Class<AdultTimeDL::APIError>] klass
      # @param [HTTParty::Response] response
      # @return [AdultTimeDL::APIError]
      def api_error(klass, response)
        endpoint = "#{response.request.base_uri}#{response.request.path}"
        klass.new(endpoint: endpoint, code: response.code,
                  body: response.parsed_response, headers: response.headers)
      end
    end
  end
end
