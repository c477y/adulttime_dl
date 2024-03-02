# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::EvilAngelDownloadLinks, type: :file_support do
  subject { described_class.new }

  include_context "config provider"
  let(:site) { "evilangel" }
  let(:placeholder_cookie) { false }
  let(:cookie_str) { ENV.fetch("EVIL_ANGEL_COOKIE_STR", "cookie") }

  before do
    # EvilAngel membership login request can be blocked by Cloudflare
    # We may need to ask the user to provide the cookie manually
    allow(subject.authenticator).to receive(:request_cookie).and_return(cookie_str)
  end

  describe "#fetch" do
    context "with valid scene" do
      let(:scene_data) do
        XXXDownload::Data::Scene.new(
          lazy: false,
          video_link: "https://www.evilangel.com/en/video/evilangel/Stunning-Curves-Scene-03/73344",
          clip_id: 73_344,
          title: "Stunning Curves, Scene #03",
          actors: [],
          network_name: "Evil Angel",
          collection_tag: "EA",
          download_sizes: %w[160p 240p 360p 480p 540p 720p 1080p 4k]
        )
      end

      before do
        VCR.use_cassette("evil_angel/download_links/stunning_curves_scene_03") do
          @result = subject.fetch(scene_data)
        end
      end

      it { expect(@result).to be_a(String) }
    end
  end
end
