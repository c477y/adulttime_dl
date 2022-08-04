# frozen_string_literal: true

require "algolia"
require "colorize"
require "dry-struct"
require "dry-types"
require "dry-validation"
require "fileutils"
require "forwardable"
require "httparty"
require "http-cookie"
require "nokogiri"
require "open3"
require "parallel"
require "set"
require "thor"
require "yaml"

require "pry"

module AdultTimeDL
  class FatalError < StandardError; end
  class SafeExit < StandardError; end

  class FileSizeTooSmallError < StandardError
    def initialize(filename, size)
      message = "[FILE SIZE TOO SMALL #{size}] #{filename}"
      super(message)
    end
  end

  class DownloadFailedError < StandardError; end

  class APIError < StandardError
    attr_reader :endpoint, :code, :body, :headers

    def initialize(endpoint:, code:, body:, headers:)
      @endpoint = endpoint
      @code = code
      @body = body
      @headers = headers
      super(message)
    end

    def fetch_error_message
      case code
      when 302 then "unexpected redirection to #{headers["location"]}"
      else (body["error"] || body["message"] || body).to_s[0..150]
      end
    end

    def message
      "API Failure:\n" \
      "\tURL: #{endpoint}\n" \
      "\tRESPONCE CODE: #{code}\n" \
      "\tERROR MESSAGE: #{fetch_error_message}"
    end
  end

  class NotFoundError < APIError; end
  class ForbiddenError < APIError; end
  class RedirectedError < APIError; end
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
require_relative "adulttime_dl/file_utils"
require_relative "adulttime_dl/constants"

require_relative "adulttime_dl/data/base"
require_relative "adulttime_dl/data/types"
require_relative "adulttime_dl/data/streaming_links"
require_relative "adulttime_dl/data/actor"
require_relative "adulttime_dl/data/scene"
require_relative "adulttime_dl/data/pornve_scene"
require_relative "adulttime_dl/data/unknown_actor_gender_scene"
require_relative "adulttime_dl/data/download_filters"
require_relative "adulttime_dl/data/urls"
require_relative "adulttime_dl/data/config"
require_relative "adulttime_dl/data/download_status_database"

require_relative "adulttime_dl/contract/download_filters_contract"
require_relative "adulttime_dl/contract/config_generator"

require_relative "adulttime_dl/net/base"
require_relative "adulttime_dl/net/browser_support"
require_relative "adulttime_dl/net/algolia_link_parser"

# Algolia Configuration
require_relative "adulttime_dl/net/algolia_client"
require_relative "adulttime_dl/net/algolia_credentials"
require_relative "adulttime_dl/net/algolia_credentials_browser"

# Download Links
require_relative "adulttime_dl/net/noop_download_links"
require_relative "adulttime_dl/net/algolia_download_links"
require_relative "adulttime_dl/net/adult_time_download_links"
require_relative "adulttime_dl/net/blowpass_download_links"
require_relative "adulttime_dl/net/ztod_download_links"

# Streaming Links
require_relative "adulttime_dl/net/algolia_streaming_links"
require_relative "adulttime_dl/net/adult_time_streaming_links"
require_relative "adulttime_dl/net/blowpass_streaming_links"
require_relative "adulttime_dl/net/love_her_films_streaming_links"
require_relative "adulttime_dl/net/pornve_streaming_links"
require_relative "adulttime_dl/net/ztod_streaming_links"

# Index
require_relative "adulttime_dl/net/adulttime_index"
require_relative "adulttime_dl/net/blowpass_index"
require_relative "adulttime_dl/net/love_her_films_index"
require_relative "adulttime_dl/net/pornve_index"
require_relative "adulttime_dl/net/ztod_index"

require_relative "adulttime_dl/downloader/command_builder"
require_relative "adulttime_dl/downloader/download"

require_relative "adulttime_dl/client"
require_relative "adulttime_dl/cli"
