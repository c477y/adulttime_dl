# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

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
require "parallel"
require "set"
require "thor"
require "yaml"
require "active_support"

require "pry" if ENV["RACK_ENV"] =~ "(dev|test)"

module XxxDownload
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
      message_from_body = (body["error"] || body["message"] || body).to_s[0..150]
      case code
      when 302 then <<-DOC
        unexpected redirection to #{headers["location"]} with response:
        #{message_from_body}
      DOC
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

  def self.logger(**opts)
    @logger ||= XXXDownload::Log.new(**opts).logger
  end

  def self.file_logger
    @file_logger ||= begin
      path = File.expand_path(File.join(Dir.pwd, "downloader.log"))
      XXXDownload.logger.info "[DOWNLOAD LOGS GENERATED TO] #{path}"
      Logger.new(path, "daily")
    end
  end
end
