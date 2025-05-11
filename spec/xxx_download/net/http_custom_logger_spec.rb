# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::HttpCustomLogger do
  let(:logger) { instance_double("Logger", debug: nil, info: nil) }
  let(:level) { :debug }
  let(:custom_logger) { described_class.new(logger, level) }

  describe "#format" do
    let(:http_method_class) { Class.new }
    let(:request) do
      instance_double(
        "HTTParty::Request",
        http_method: http_method_class,
        uri: class_double(URI, to_s: "https://example.com/test"),
        path: "/test"
      )
    end

    before { allow(http_method_class).to receive(:name).and_return("Net::HTTP::Get") }

    let(:response) do
      instance_double(
        "HTTParty::Response",
        code: 200,
        headers: { "Content-Length" => "1024", "Content-Type" => "application/json" }
      )
    end

    it "sends a formatted message to the logger" do
      expect(logger).to receive(level).with(a_string_matching(/REQUEST: GET/))
      custom_logger.format(request, response)
    end
  end
end
