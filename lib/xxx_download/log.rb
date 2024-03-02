# frozen_string_literal: true

module XXXDownload
  class CustomLogger < Logger
    EXTRA = Logger::DEBUG - 2
    TRACE = Logger::DEBUG - 1

    SEV_LABEL = {
      -2 => "EXTRA",
      -1 => "TRACE",
      0 => "DEBUG",
      1 => "INFO",
      2 => "WARN",
      3 => "ERROR",
      4 => "FATAL"
    }.freeze

    def format_severity(severity)
      SEV_LABEL[severity] || "ANY"
    end

    def trace(message)
      add(TRACE, message)
    end

    def extra(message)
      add(EXTRA, message)
    end
  end

  class Log
    attr_accessor :logger

    # @param [Logger::logdev] logdev Can be a file or $stdout
    # @param [String] level one of "extra", "trace", "debug", "info", "warn", "error", "fatal"
    def initialize(logdev, level) # rubocop:disable Metrics/CyclomaticComplexity
      @logger = CustomLogger.new(logdev)
      @logger.level = log_level(level)
      @logger.formatter = proc do |severity, datetime, _progname, msg|
        date_format = datetime.strftime("%H:%M:%S")
        case severity.upcase
        when "FATAL" then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:red)} #{msg}\n"
        when "ERROR" then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:light_red)} #{msg}\n"
        when "WARN"  then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:yellow)} #{msg}\n"
        when "INFO"  then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:green)} #{msg}\n"
        when "DEBUG" then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:blue)} #{msg}\n"
        when "TRACE" then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:light_blue)} #{msg}\n"
        when "EXTRA" then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:magenta)} #{msg}\n"
        else "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:cyan)} #{msg}\n"
        end
      end
    end

    def log_level(level) # rubocop:disable Metrics/CyclomaticComplexity
      case level.upcase
      when "EXTRA" then CustomLogger::EXTRA
      when "TRACE" then CustomLogger::TRACE
      when "DEBUG" then CustomLogger::DEBUG
      when "INFO"  then CustomLogger::INFO
      when "WARN"  then CustomLogger::WARN
      when "ERROR" then CustomLogger::ERROR
      when "FATAL" then CustomLogger::FATAL
      else raise "Invalid log level #{level}"
      end
    end
  end
end
