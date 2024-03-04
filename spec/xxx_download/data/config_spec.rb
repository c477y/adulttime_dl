# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Data::Config, type: :file_support do
  include_context "config provider"
  include_context "fake scene provider"

  subject { config }

  describe "#cookie" do
    context "when cookie file exists" do
      it "returns cookie value" do
        expect(subject.cookie).to eq("cookie_name=cookie_value")
      end
    end
  end

  describe "#dry_run?" do
    context "when dry_run is true" do
      let(:override_config) { { dry_run: true } }

      it { expect(subject.dry_run?).to be true }
    end

    context "when dry_run is false" do
      let(:override_config) { { dry_run: false } }

      it { expect(subject.dry_run?).to be false }
    end
  end

  describe "#skip_scene?" do
    it { expect(subject.skip_scene?(scene)).to eq(false) }
  end

  describe "#downloader_requires_cookie?" do
    context "when site requires cookie to download" do
      let(:site) { "loveherfilms" }

      it "returns true" do
        expect(subject.downloader_requires_cookie?).to be true
      end
    end

    context "when site does not require cookie to download" do
      it { expect(subject.downloader_requires_cookie?).to be false }
    end
  end

  describe "streaming_link_fetcher" do
    let(:sitemap) do
      {
        "adulttime" => XXXDownload::Net::AdultTimeStreamingLinks,
        "blowpass" => XXXDownload::Net::BlowpassStreamingLinks,
        "loveherfilms" => XXXDownload::Net::LoveHerFilmsStreamingLinks,
        "pornve" => XXXDownload::Net::PornveStreamingLinks,
        "ztod" => XXXDownload::Net::ZtodStreamingLinks
      }
    end
    described_class::MODULE_NAME.each_pair do |site, _|
      describe "#streaming_link_fetcher for #{site}" do
        let(:site) { site }
        if XXXDownload::Data::Config::STREAMING_UNSUPPORTED_SITE.include?(site)
          it "returns an instance of NoopLinkFetcher" do
            expect(config.streaming_link_fetcher).to be_an_instance_of(XXXDownload::Net::NoopLinkFetcher)
          end
        else
          it "returns an instance of the appropriate link fetcher" do
            expect(config.streaming_link_fetcher).to be_an_instance_of(sitemap[site])
          end
        end
      end
    end
  end

  describe "download_link_fetcher" do
    let(:sitemap) do
      {
        "adulttime" => XXXDownload::Net::AdultTimeDownloadLinks,
        "archangel" => XXXDownload::Net::ArchAngelDownloadLinks,
        "blowpass" => XXXDownload::Net::BlowpassDownloadLinks,
        "cumlouder" => XXXDownload::Net::CumLouderDownloadLinks,
        "goodporn" => XXXDownload::Net::GoodpornDownloadLinks,
        "houseofyre" => XXXDownload::Net::HouseOFyreDownloadLinks,
        "julesjordan" => XXXDownload::Net::JulesJordanDownloadLinks,
        "manuelferrara" => XXXDownload::Net::JulesJordanDownloadLinks,
        "scoregroup" => XXXDownload::Net::ScoreGroupDownloadLinks,
        "ztod" => XXXDownload::Net::ZtodDownloadLinks
      }
    end
    described_class::MODULE_NAME.each_pair do |site, _|
      describe "#download_link_fetcher for #{site}" do
        let(:site) { site }
        if XXXDownload::Data::Config::DOWNLOADING_UNSUPPORTED_SITE.include?(site)
          it "returns an instance of NoopLinkFetcher" do
            expect(config.download_link_fetcher).to be_an_instance_of(XXXDownload::Net::NoopLinkFetcher)
          end
        else
          it "returns an instance of the appropriate link fetcher" do
            expect(config.download_link_fetcher).to be_an_instance_of(sitemap[site])
          end
        end
      end
    end
  end

  describe "scenes_index" do
    let(:sitemap) do
      {
        "adulttime" => XXXDownload::Net::AdultTimeIndex,
        "archangel" => XXXDownload::Net::ArchAngelIndex,
        "blowpass" => XXXDownload::Net::BlowpassIndex,
        "cumlouder" => XXXDownload::Net::CumLouderIndex,
        "goodporn" => XXXDownload::Net::GoodpornIndex,
        "houseofyre" => XXXDownload::Net::HouseOFyreIndex,
        "julesjordan" => XXXDownload::Net::JulesJordanIndex,
        "loveherfilms" => XXXDownload::Net::LoveHerFilmsIndex,
        "manuelferrara" => XXXDownload::Net::JulesJordanIndex,
        "pornve" => XXXDownload::Net::PornveIndex,
        "scoregroup" => XXXDownload::Net::ScoreGroupIndex,
        "ztod" => XXXDownload::Net::ZtodIndex
      }
    end
    described_class::MODULE_NAME.each_pair do |site, _|
      describe "#scenes_index for #{site}" do
        let(:site) { site }
        it "returns an instance of the appropriate link fetcher" do
          expect(config.scenes_index).to be_an_instance_of(sitemap[site])
        end
      end
    end
  end

  context "when class generation is called with invalid arguments" do
    it "raises an error" do
      binding.pry
      expect { config.send(:generate_class, "foo", "bar") }
        .to raise_error(XXXDownload::FatalError, "[INIT FAILURE] XXXDownload::Net::bar")
    end
  end

  describe "current_site_config" do
    context "when site is blowpass" do
      let(:site) { "blowpass" }

      it { expect(config.current_site_config).to include(:algolia_application_id, :algolia_api_key) }
    end
  end
end
