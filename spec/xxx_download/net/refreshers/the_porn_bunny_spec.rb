# frozen_string_literal: true

require "rspec"

class FakeWebDriverProvider
  include XXXDownload::Net::BrowserSupport

  def initialize
    # Uncomment during live-test
    # start_browser
    nil
  end
end

RSpec.describe XXXDownload::Net::Refreshers::ThePornBunny, type: :file_support do
  include_context "config provider"

  subject { described_class.new(path) }

  let(:web_driver) { FakeWebDriverProvider.new.default_options }

  before do # uncomment during live-testing
    allow(subject).to receive(:setup).and_return(nil)
    allow(subject).to receive(:load_interceptor).and_return(nil)
    allow(subject).to receive(:fetch_video_page!).and_return(nil)
  end

  describe "#refresh" do
    let(:result) { subject.refresh }
    context "when scene exists" do
      let(:path) { "/video/stuck-and-sucked/" }

      let(:expected_scene) do
        {
          lazy: false,
          video_link: "https://www.thepornbunny.com/video/stuck-and-sucked/",
          title: "Stuck and Sucked",
          actors: [{ name: "Abella Danger", gender: "unknown" }, { name: "JMac", gender: "unknown" }],
          network_name: "RK Prime",
          collection_tag: "TPB",
          duration: "26:05",
          download_sizes: %w[1080 720 480 360]
        }
      end

      it "returns the expected scene data", :aggregate_failures do
        pending "Requires browser session"

        expect(result).to be_a(XXXDownload::Data::Scene)
        expect(result.to_h).to include(expected_scene)
        expect(result.downloading_links).to be_a(XXXDownload::Data::StreamingLinks)
      end
    end

    context "when scene does not exist" do
      let(:path) { "/video/fff" }

      it "returns the expected scene data", :aggregate_failures do
        pending "Requires browser session"

        expect(result).to be_a(XXXDownload::Data::Scene)
        expect(result.fail?).to eq(true)
        expect(result.downloading_links).to be_a(XXXDownload::Data::StreamingLinks)
      end
    end
  end
end
