# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::RickysRoomIndex, type: :file_support do
  subject { described_class.new }

  include_context "config provider"
  let(:placeholder_cookie) { false }
  let(:cookie_str) { ENV.fetch("RICKYS_ROOM_COOKIE_STR", "cookie") }

  describe "#search_by_all_scenes" do
    context "when a scene exists" do
      before do
        # Comment this lines if you have live-credentials to a membership account
        # This will spawn the browser and ask the user for credentials
        allow(subject).to receive(:request_cookie).and_return(cookie_str)

        VCR.use_cassette("rickys_room_index_search_by_all_scenes#valid_scene") do
          @result = subject.search_by_all_scenes(resource)
        end
      end

      let(:resource) { "https://members.rickysroom.com/videos/exploring-a-perfect-arch" }
      let(:expected_scene) do
        {
          lazy: false,
          video_link: "https://www.rickysroom.com/scenes/exploring-a-perfect-arch",
          title: "Exploring A Perfect Arch",
          actors: [{ name: "Ricky Johnson", gender: "unknown" }, { name: "Gal Ritchie", gender: "unknown" }],
          network_name: "Ricky's Room",
          collection_tag: "rir",
          tags: %w[blackhair blowjob cowgirl cuminmouth doggy facial naturaltits pussylick tattoos toesucking],
          duration: "44:40",
          release_date: "2024-04-04",
          download_sizes: %w[hd sd fhd 4k]
        }
      end
      let(:download_link_keys) { %i[res_2160p res_1080p res_720p res_360p default] }

      it "returns the expected scene data", :aggregate_failures do
        expect(@result.length).to eq(1)
        expect(@result.first).to be_a(XXXDownload::Data::Scene)
        expect(@result.first.to_h).to include(expected_scene)
        expect(@result.first.downloading_links).to be_a(XXXDownload::Data::StreamingLinks)
        expect(@result.first.downloading_links.to_h.keys).to match_array(download_link_keys)
      end
    end

    context "when a scene does not exist" do
      before do
        # Comment this lines if you have live-credentials to a membership account
        # This will spawn the browser and ask the user for credentials
        allow(subject).to receive(:request_cookie).and_return(cookie_str)

        VCR.use_cassette("rickys_room_index_search_by_all_scenes#invalid_scene") do
          @result = subject.search_by_all_scenes(resource)
        end
      end

      let(:resource) { "https://members.rickysroom.com/videos/fff" }

      it "returns the expected scene data", :aggregate_failures do
        expect(@result.length).to eq(0)
      end
    end
  end

  describe "#search_by_actor" do
    context "when actor exists" do
      before do
        # Comment this lines if you have live-credentials to a membership account
        # This will spawn the browser and ask the user for credentials
        allow(subject).to receive(:request_cookie).and_return(cookie_str)

        VCR.use_cassette("rickys_room_index_search_by_actor#angel-youngs") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://members.rickysroom.com/models/kazumi" }

      it "returns an array of expected_scenes", :aggregate_failures do
        expect(@result).to all(be_a(XXXDownload::Data::Scene))
        expect(@result).to all(have_attributes(lazy?: false))
        expect(@result).to all(have_attributes(video_link: start_with("https://www.rickysroom.com/scenes/")))
        expect(@result).to all(have_attributes(downloading_links: be_a(XXXDownload::Data::StreamingLinks)))
      end
    end

    context "when actor does not exists" do
      before do
        # Comment this lines if you have live-credentials to a membership account
        # This will spawn the browser and ask the user for credentials
        allow(subject).to receive(:request_cookie).and_return(cookie_str)

        VCR.use_cassette("rickys_room_index_search_by_actor#fff") do
          @result = subject.search_by_actor(resource)
        end
      end
      let(:resource) { "https://members.rickysroom.com/models/fff" }

      it "returns an empty array", :aggregate_failures do
        expect(@result).to be_empty
      end
    end
  end

  describe "#search_by_page" do
    context "when page has scenes" do
      before do
        # Comment this lines if you have live-credentials to a membership account
        # This will spawn the browser and ask the user for credentials
        allow(subject).to receive(:request_cookie).and_return(cookie_str)

        VCR.use_cassette("rickys_room_index_search_by_page#with_scenes") do
          @result = subject.search_by_page(resource)
        end
      end

      let(:resource) { "https://members.rickysroom.com/videos?page=1&order_by=publish_date&sort_by=desc" }

      it "returns an array of expected_scenes", :aggregate_failures do
        expect(@result).to all(be_a(XXXDownload::Data::Scene))
        expect(@result).to all(have_attributes(lazy?: true))
        expect(@result).to all(have_attributes(video_link: start_with("/videos/")))
        expect(@result).to all(have_attributes(refresher: be_a(XXXDownload::Net::Refreshers::YppRefresh)))
      end
    end

    context "when page has no scenes" do
      before do
        # Comment this lines if you have live-credentials to a membership account
        # This will spawn the browser and ask the user for credentials
        allow(subject).to receive(:request_cookie).and_return(cookie_str)

        VCR.use_cassette("rickys_room_index_search_by_page#no_scenes") do
          @result = subject.search_by_page(resource)
        end
      end

      let(:resource) { "https://members.rickysroom.com/videos?page=100&order_by=publish_date&sort_by=desc" }

      it "returns an array of expected_scenes", :aggregate_failures do
        expect(@result.length).to eq(0)
      end
    end
  end
end
