# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::ZtodDownloadLinks, type: :file_support do
  subject { described_class.new }

  include_context "config provider"
  let(:site) { "ztod" }
  let(:placeholder_cookie) { false }
  let(:cookie_str) { ENV.fetch("ZTOD_COOKIE_STR", "cookie") }

  before do
    allow(subject.authenticator).to receive(:request_cookie).and_return(cookie_str)
  end

  describe "#fetch" do
    context "with valid scene" do
      let(:scene_data) do
        XXXDownload::Data::Scene.new(
          lazy: false,
          video_link: "https://www.zerotolerancefilms.com/en/video/3rddegreefilms/Witness-The-Thickness-Hot-And-Heavy---Scene-1/194947",
          clip_id: 194_947,
          title: "Witness The Thickness: Hot And Heavy - Scene 1",
          actors: [{ name: "Keira Croft", gender: "female" }, { name: "Lucas Frost", gender: "male" }],
          network_name: "Zero Tolerance Films",
          collection_tag: "ZT",
          tags: ["straight"],
          duration: "00:25:18",
          release_date: "2024-03-11",
          movie_title: "Witness The Thickness: Hot And Heavy",
          download_sizes: %w[160p 240p 360p 480p 540p 720p 1080p 4k]
        )
      end

      before do
        VCR.use_cassette("ztod_download_links_fetch#valid_scene_witness_the_thickness") do
          @result = subject.fetch(scene_data)
        end
      end

      pending "The VCR cassette is broken for this test"
      # it { expect(@result).to be_a(String) }
    end

    context "with an invalid scene" do
      let(:scene_data) do
        XXXDownload::Data::Scene.new(
          lazy: false,
          video_link: "https://www.zerotolerancefilms.com/en/video/3rddegreefilms/xxx/111",
          clip_id: 123,
          title: "xxx",
          actors: [],
          network_name: "Zero Tolerance Films",
          collection_tag: "ZT",
          tags: [],
          download_sizes: %w[160p 240p 360p 480p 540p 720p 1080p 4k]
        )
      end

      before do
        VCR.use_cassette("ztod_download_links_fetch#invalid_scene_xxx") do
          @result = subject.fetch(scene_data)
        end
      end

      pending "The VCR cassette is broken for this test"
      # it { expect(@result).to be_nil }
    end
  end
end
