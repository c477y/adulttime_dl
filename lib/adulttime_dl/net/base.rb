# frozen_string_literal: true

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
