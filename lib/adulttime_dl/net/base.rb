# frozen_string_literal: true

module AdultTimeDL
  module Net
    class Base
      def default_headers
        {
          "User-Agent" => "Mozilla/5.0 (Windows NT x.y; rv:10.0) Gecko/20100101 Firefox/10.0",
          "Accept" => "application/json",
        }
      end

      # @param [HTTParty::Response] response
      def handle_response!(response)
        case response.code
        when 200 then response.parsed_response
        when 400 then raise api_error(BadRequestError, response)
        when 401 then raise api_error(UnauthorizedError, response)
        when 403 then raise api_error(ForbiddenError, response)
        when 404 then raise api_error(NotFoundError, response)
        when 500 then raise api_error(BadGatewayError, response)
        else raise api_error(UnhandledError, response)
        end
      end

      private

      # @param [Class<AdultTimeDL::APIError>] klass
      # @param [HTTParty::Response] response
      # @return [AdultTimeDL::APIError]
      def api_error(klass, response)
        klass.new(endpoint: response.request.path, code: response.code, body: response.parsed_response)
      end
    end
  end
end
