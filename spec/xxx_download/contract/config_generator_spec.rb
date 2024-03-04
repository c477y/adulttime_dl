# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Contract::ConfigGenerator, type: :file_support do
  describe ".generate" do
    subject(:generate) { described_class.new(site, options).generate }
    let(:site) { "goodporn" }
    let(:options) { {} }

    context "when no config file exists" do
      let(:generated_config_file) { "config.yml" }

      it "should raise an error" do
        expect { generate }.to raise_error(XXXDownload::SafeExit, "DEFAULT_FILE_GENERATION")
      end

      it "should create a valid config file" do
        expect { generate }.to raise_error(XXXDownload::SafeExit, "DEFAULT_FILE_GENERATION")
        expect(File.exist?(generated_config_file)).to be true
        expect { YAML.load_file(generated_config_file) }.not_to raise_error
      end
    end

    context "when a config file exists" do
      include_context "config provider"

      context "with no overrides" do
        it "should give a valid config file" do
          expect(generate.to_h.deep_transform_keys!(&:to_s)).to include(XXXDownload::Contract::Default.cleaned_config)
        end
      end

      context "when site is invalid" do
        let(:site) { "invalid" }

        it { expect { generate }.to raise_error(XXXDownload::FatalError) }
      end

      context "when skip keywords are provided" do
        let(:override_config) do
          { "download_filters" => {
            "skip_studios" => ["abc"],
            "oldest_year" => 1990,
            "skip_lesbian" => true
          } }
        end

        it { expect(generate.download_filters.skip_studios).to include("abc") }
        it { expect(generate.download_filters.oldest_year).to eq(1990) }
        it { expect(generate.download_filters.skip_lesbian).to eq(true) }
      end

      context "when youtube-dl is not installed" do
        before do
          allow(Open3).to receive(:capture3).and_return(["", "", double(success?: false)])
        end

        it {
          expect { generate }.to raise_error(XXXDownload::FatalError,
                                             /\[downloader\] is not installed or unavailable on \$PATH/)
        }
      end

      context "with performer URL" do
        context "when a URL is provided" do
          let(:override_config) { { "urls" => { "performers" => ["https://www.goodporn.com"] } } }

          it { expect(generate.urls.performers).to include("https://www.goodporn.com") }
        end

        context "when a URL is not provided" do
          let(:override_config) { { "urls" => { "performers" => nil } } }

          it { expect(generate.urls.performers).to be_empty }
        end
      end
    end
  end
end
