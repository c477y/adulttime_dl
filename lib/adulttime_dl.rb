# frozen_string_literal: true

require "httparty"
require "nokogiri"
require "colorize"
require "dry-struct"
require "dry-types"

require "pry"

module AdultTimeDL
  class FatalError < StandardError; end

  class APIError < StandardError
    attr_reader :endpoint, :code, :body

    def initialize(endpoint:, code:, body:)
      @endpoint = endpoint
      @code = code
      @body = body
      super(message)
    end

    def fetch_error_message
      err = body["error"] || body["message"] || body
      err.to_s
    end

    def message
      "API request to #{endpoint} failed with code #{code}. The error was: #{fetch_error_message}"
    end
  end

  class NotFoundError < APIError; end
  class ForbiddenError < APIError; end
  class BadRequestError < APIError; end
  class BadGatewayError < APIError; end
  class UnhandledError < APIError; end
  class UnauthorizedError < APIError; end

  def self.logger(**opts)
    @logger ||= AdultTimeDL::Log.new(**opts).logger
  end
end

require_relative "adulttime_dl/version"
require_relative "adulttime_dl/log"

require_relative "adulttime_dl/data/base"
require_relative "adulttime_dl/data/types"
require_relative "adulttime_dl/data/algolia_actor"
require_relative "adulttime_dl/data/algolia_scene"
require_relative "adulttime_dl/data/streaming_links"

require_relative "adulttime_dl/net/base"
require_relative "adulttime_dl/net/algolia_credentials"
require_relative "adulttime_dl/net/query"
require_relative "adulttime_dl/net/streaming_links"
