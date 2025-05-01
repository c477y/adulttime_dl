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
        "loveherfilms" => XXXDownload::Net::LoveHerFilmsStreamingLinks,
        "pornve" => XXXDownload::Net::PornveStreamingLinks
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
        "bellesa" => XXXDownload::Net::BellesaDownloadLinks,
        "blowpass" => XXXDownload::Net::BlowpassDownloadLinks,
        "cumlouder" => XXXDownload::Net::CumLouderDownloadLinks,
        "evilangel" => XXXDownload::Net::EvilAngelDownloadLinks,
        "houseofyre" => XXXDownload::Net::HouseOFyreDownloadLinks,
        "julesjordan" => XXXDownload::Net::JulesJordanDownloadLinks,
        "manuelferrara" => XXXDownload::Net::ManuelFerraraDownloadLinks,
        "newsensations" => XXXDownload::Net::NewSensationsDownloadLinks,
        "pornfidelity" => XXXDownload::Net::PornfidelityDownloadLinks,
        "rickysroom" => XXXDownload::Net::RickysRoomDownloadLinks,
        "s3xus" => XXXDownload::Net::S3xusDownloadLinks,
        "spizoo" => XXXDownload::Net::SpizooDownloadLinks,
        "scoregroup" => XXXDownload::Net::ScoreGroupDownloadLinks,
        "thepornbunny" => XXXDownload::Net::ThePornBunnyDownloadLinks,
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
    before do
      # Pornfidelity
      allow_any_instance_of(XXXDownload::Net::PornfidelityIndex).to receive(:start_browser).and_return(nil)
      allow_any_instance_of(XXXDownload::Net::PornfidelityIndex).to receive(:load_interceptor).and_return(nil)

      # NewSensations
      allow_any_instance_of(XXXDownload::Net::NewSensationsIndex).to receive(:start_browser).and_return(nil)
    end
    let(:sitemap) do
      {
        "adulttime" => XXXDownload::Net::AdultTimeIndex,
        "archangel" => XXXDownload::Net::ArchAngelIndex,
        "bellesa" => XXXDownload::Net::BellesaIndex,
        "blowpass" => XXXDownload::Net::BlowpassIndex,
        "cumlouder" => XXXDownload::Net::CumLouderIndex,
        "evilangel" => XXXDownload::Net::EvilAngelIndex,
        "houseofyre" => XXXDownload::Net::HouseOFyreIndex,
        "julesjordan" => XXXDownload::Net::JulesJordanIndex,
        "loveherfilms" => XXXDownload::Net::LoveHerFilmsIndex,
        "manuelferrara" => XXXDownload::Net::ManuelFerraraIndex,
        "newsensations" => XXXDownload::Net::NewSensationsIndex,
        "pornfidelity" => XXXDownload::Net::PornfidelityIndex,
        "rickysroom" => XXXDownload::Net::RickysRoomIndex,
        "s3xus" => XXXDownload::Net::S3xusIndex,
        "scoregroup" => XXXDownload::Net::ScoreGroupIndex,
        "spizoo" => XXXDownload::Net::SpizooIndex,
        "thepornbunny" => XXXDownload::Net::ThePornBunnyIndex,
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
      expect { config.send(:generate_class, "foo", "bar") }
        .to raise_error(XXXDownload::FatalError, /\[INIT FAILURE\] XXXDownload::Net::bar/)
    end
  end

  describe "current_site_config" do
    context "when site is blowpass" do
      let(:site) { "blowpass" }

      it { expect(config.current_site_config).to include(:algolia_application_id, :algolia_api_key) }
    end
  end
end
