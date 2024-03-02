# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem

# Custom inflections to make Zeitwerk work
# Avoid creating new inflections unnecessarily
loader.inflector.inflect(
  "xxx_download" => "XXXDownload",
  "urls" => "URLs",
  "http_generator" => "HTTPGenerator"
)

loader.setup

require "active_support"
require "active_support/core_ext"
require "algolia"
require "awesome_print"
require "colorize"
require "deep_merge/rails_compat"
require "dry-struct"
require "dry-types"
require "dry-validation"
require "fileutils"
require "http-cookie"
require "httparty"
require "nokogiri"
require "parallel"
require "set"
require "thor"
require "yaml"

require "pry" if ENV.fetch("RACK_ENV", "").match?(/(dev.*|test)/)

module XXXDownload
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

    def error_message
      message_from_body = case body
                          when Hash then (body["error"] || body["message"] || body).to_s[0..150]
                          when String then body[0..150]
                          when NilClass then "no response body"
                          else
                            "unknown error message format #{body.class}"
                          end
      case code
      when 302 then "unexpected redirection to #{headers["location"]} with response: #{message_from_body}"
      else message_from_body
      end
    end

    def message
      "API Failure:\n" \
        "\tURL: #{endpoint}\n" \
        "\tRESPONSE CODE: #{code}\n" \
        "\tERROR MESSAGE: #{error_message}"
    end
  end

  class NotFoundError < APIError; end

  class ForbiddenError < APIError; end

  class RedirectedError < APIError; end

  class BadRequestError < APIError; end

  class BadGatewayError < APIError; end

  class UnhandledError < APIError; end

  class UnauthorizedError < APIError; end

  class TooManyRequestsError < APIError; end

  class InternalServerError < APIError; end

  # @return [Logger]
  def self.logger
    raise FatalError, "tried to access logger, but it was not initialised" unless defined?(@logger)

    @logger
  end

  def self.file_logger
    @file_logger ||= if test?
                       XXXDownload.logger.info "[TEST ENV] File logging disabled."
                       Logger.new(File::NULL)
                     else
                       path = File.expand_path(File.join(Dir.pwd, "downloader.log"))
                       XXXDownload.logger.info "[DOWNLOAD LOGS GENERATED TO] #{path}"
                       Logger.new(path, "daily")
                     end
  end

  # @return [Data::Config]
  def self.config
    raise FatalError, "tried to access config, but it was not assigned" unless defined?(@config)

    @config
  end

  # @param [Data::Config] config
  def self.set_config(config) # rubocop:disable Naming/AccessorMethodName
    @config = config
  end

  def self.set_logger(level) # rubocop:disable Naming/AccessorMethodName
    @logger = XXXDownload::Log.new($stdout, level).logger
    # Also initialise the file logger before we start changing directories mid-execution
    file_logger
  end

  def self.test?
    ENV["RACK_ENV"] == "test"
  end

  def self.dev?
    ENV["RACK_ENV"].match?(/dev/)
  end
end
