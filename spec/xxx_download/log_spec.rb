# frozen_string_literal: true

require "spec_helper"

RSpec.describe XXXDownload::Log do
  let(:logdev) { StringIO.new }
  let(:level) { "EXTRA" }
  let(:log_instance) { described_class.new(logdev, level) }

  describe "#initialize" do
    it "creates a logger instance" do
      expect(log_instance.logger).to be_a(XXXDownload::CustomLogger)
    end

    it "sets the correct log level" do
      expect(log_instance.logger.level).to eq(XXXDownload::CustomLogger::EXTRA)
    end

    it "raises an error for invalid log levels" do
      expect { described_class.new(logdev, "INVALID") }.to raise_error("Invalid log level INVALID")
    end

    it "sets the logger formatter" do
      expect(log_instance.logger.formatter).to be_a(Proc)
    end
  end

  describe "logger formatting" do
    it "formats INFO messages" do
      log_instance.logger.info("This is an info message")
      result = logdev.string
      expect(result).to include("[INFO ]")
    end

    it "formats WARN messages" do
      log_instance.logger.warn("This is a warn message")
      result = logdev.string
      expect(result).to include("[WARN ]")
    end

    it "formats ERROR messages" do
      log_instance.logger.error("This is an error message")
      result = logdev.string
      expect(result).to include("[ERROR]")
    end

    it "formats FATAL messages" do
      log_instance.logger.fatal("This is a fatal message")
      result = logdev.string
      expect(result).to include("[FATAL]")
    end

    it "formats DEBUG messages" do
      log_instance.logger.debug("This is a debug message")
      result = logdev.string
      expect(result).to include("[DEBUG]")
    end

    it "formats TRACE messages" do
      log_instance.logger.add(XXXDownload::CustomLogger::TRACE, "This is a trace message")
      result = logdev.string
      expect(result).to include("[TRACE]")
    end

    it "formats EXTRA messages" do
      log_instance.logger.add(XXXDownload::CustomLogger::EXTRA, "This is an extra message")
      result = logdev.string
      expect(result).to include("[EXTRA]")
    end

    it "formats unknown severity messages" do
      log_instance.logger.add(9999, "This is an unknown severity message")
      result = logdev.string
      expect(result).to include("[ANY  ]")
    end
  end
end
