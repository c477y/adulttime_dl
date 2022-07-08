# frozen_string_literal: true

module AdultTimeDL
  class Log
    attr_accessor :logger

    def initialize(logdev = $stdout, **opts)
      @logger = Logger.new(logdev)
      @logger.level = opts[:verbose] ? "DEBUG" : "INFO"
      @logger.formatter = proc do |severity, datetime, _progname, msg|
        date_format = datetime.strftime("%H:%M:%S")
        case severity
        when "FATAL" then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:red)} #{msg}\n"
        when "ERROR" then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:light_red)} #{msg}\n"
        when "WARN"  then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:yellow)} #{msg}\n"
        when "INFO"  then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:blue)} #{msg}\n"
        when "DEBUG" then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:magenta)} #{msg}\n"
        else "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:cyan)} #{msg}\n"
        end
      end
    end
  end
end
