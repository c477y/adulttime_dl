# frozen_string_literal: true

require "algolia"
require "colorize"
require "dry-struct"
require "dry-types"
require "forwardable"
require "httparty"
require "nokogiri"
require "open3"
require "parallel"
require "thor"
require "yaml"

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

  def self.file_logger
    @file_logger ||= Logger.new("downloader.log", "daily")
  end
end

require_relative "adulttime_dl/version"
require_relative "adulttime_dl/log"
require_relative "adulttime_dl/utils"

require_relative "adulttime_dl/data/base"
require_relative "adulttime_dl/data/types"
require_relative "adulttime_dl/data/streaming_links"
require_relative "adulttime_dl/data/algolia_actor"
require_relative "adulttime_dl/data/algolia_scene"
require_relative "adulttime_dl/data/download_status_database"
require_relative "adulttime_dl/data/config"

require_relative "adulttime_dl/net/base"
require_relative "adulttime_dl/net/algolia_credentials"
require_relative "adulttime_dl/net/streaming_links"
require_relative "adulttime_dl/net/scenes_index"

require_relative "adulttime_dl/downloader/command_builder"
require_relative "adulttime_dl/downloader/download"

require_relative "adulttime_dl/processor/performer_processor"

require_relative "adulttime_dl/client"
require_relative "adulttime_dl/cli"
