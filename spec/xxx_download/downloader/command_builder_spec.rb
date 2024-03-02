# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Downloader::CommandBuilder, type: :file_support do
  context "with no options provided" do
    it {
      expect { described_class.build }
        .to raise_error(XXXDownload::FatalError, "[COMMAND BUILDER] no configuration provided")
    }
  end

  context "with no mandatory keys specified" do
    let(:builder) do
      described_class.build(&:merge_parts)
    end

    it {
      expect { builder }
        .to raise_error(XXXDownload::Downloader::CommandBuilder::BadCommandError,
                        /Missing download_client, url, path/)
    }
  end

  context "with download client not specified" do
    let(:builder) do
      described_class.build do |builder|
        builder.path("test")
        builder.url("https://www.example.com")
      end
    end

    it {
      expect { builder }
        .to raise_error(XXXDownload::Downloader::CommandBuilder::BadCommandError, /Missing download_client/)
    }
  end

  context "with all keys specified" do
    let(:expected_command) do
      "youtube-dl \"https://www.example.com\" --cookies test_cookie -o '/test.%(ext)s' " \
        "--verbose --dump-pages --test-external-flags --merge-output-format mkv " \
        "-f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]'"
    end
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

  describe "build_basic" do
    include_context "config provider"

    context "when no block is provided" do
      it "raises a FatalError" do
        expect do
          described_class.build_basic
        end.to raise_error(XXXDownload::FatalError, "[COMMAND BUILDER] no configuration provided")
      end
    end

    context "when a block is provided" do
      let(:builder) do
        described_class.build_basic do |b|
          b.url("https://www.example.com")
          b.path("test")
        end
      end

      it "does not raise an error" do
        expect { builder }.not_to raise_error
      end

      it "returns a command string" do
        expect(builder)
          .to eq("youtube-dl \"https://www.example.com\" " \
                 "-o '/test.%(ext)s' --external-downloader aria2c " \
                 "--external-downloader-args \"-j 8 -s 8 -x 8 -k 5M\"")
      end
    end

    context "when mandatory keys are missing" do
      let(:builder) do
        described_class.build_basic do |b|
          b.download_client("youtube-dl")
        end
      end

      it "raises a BadCommandError" do
        expect { builder }.to raise_error(XXXDownload::Downloader::CommandBuilder::BadCommandError, /Missing url, path/)
      end
    end
  end
end
