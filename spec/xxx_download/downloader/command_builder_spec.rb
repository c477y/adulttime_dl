# frozen_string_literal: true

require 'rspec'

RSpec.describe XXXDownload::Downloader::CommandBuilder do
  context "with no options provided" do
    it { expect { described_class.build }
           .to raise_error(XXXDownload::FatalError, "[COMMAND BUILDER] no configuration provided") }
  end

  context "with no mandatory keys specified" do
    let(:builder) do
      described_class.build do |builder|
        builder.merge_parts
      end
    end

    it { expect { builder }
           .to raise_error(XXXDownload::Downloader::CommandBuilder::BadCommandError, /Missing download_client, url, path/) }
  end

  context "with download client not specified" do
    let(:builder) do
      described_class.build do |builder|
        builder.path("test")
        builder.url("https://www.example.com")
      end
    end

    it { expect { builder }
           .to raise_error(XXXDownload::Downloader::CommandBuilder::BadCommandError, /Missing download_client/) }
  end

  context "with all keys specified" do
    let(:expected_command) { "youtube-dl \"https://www.example.com\" --cookies test_cookie -o '/test.%(ext)s' " \
                              "--verbose --dump-pages --test-external-flags --merge-output-format mkv " \
                              "-f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]'" }
    let(:builder) do
      described_class.build do |builder|
        builder.download_client("youtube-dl")
        builder.path("test")
        builder.url("https://www.example.com")
        builder.merge_parts
        builder.parallel(2)
        builder.quality("1080")
        builder.cookie("test_cookie")
        builder.external_flags("--test-external-flags")
        builder.verbose
      end
    end

    it "builds a command" do
      expect(builder).to eq(expected_command)
    end
  end
end
