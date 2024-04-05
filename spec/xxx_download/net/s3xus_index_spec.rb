# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::S3xusIndex, type: :file_support do
  subject { described_class.new }

  include_context "config provider"
  let(:cookie_str) { ENV.fetch("S3XUS_COOKIE_STR", "cookie") }

  describe "#search_by_all_scenes" do
    context "when a scene exists" do
      before do
        # Comment this lines if you have live-credentials to a membership account
        # This will spawn the browser and ask the user for credentials
        allow(subject).to receive(:request_cookie).and_return(cookie_str)

        VCR.use_cassette("s3xus_index_search_by_all_scenes#valid_scene") do
          @result = subject.search_by_all_scenes(resource)
        end
      end

      let(:resource) { "https://members.s3xus.com/scenes/vertigo" }
      let(:expected_scene) do
        {
          lazy: false,
          video_link: "https://www.s3xus.com/scenes/vertigo",
          title: "Vertigo",
          actors: [{ name: "Melissa Stratton", gender: "female" }, { name: "Brad Newman", gender: "male" }],
          network_name: "S3xus",
          collection_tag: "S3x",
          tags: %w[bigtits blowjob brunette cowgirl cumontits cumshot doggy pussylick reversecowgirl titfuck],
          duration: "37:29",
          release_date: "2024-04-05",
          download_sizes: %w[hd sd fhd 4k]
        }
      end
      let(:download_link_keys) { %i[res_2160p res_1080p res_270p default] }

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

        VCR.use_cassette("s3xus_index_search_by_all_scenes#invalid_scene") do
          @result = subject.search_by_all_scenes(resource)
        end
      end

      let(:resource) { "https://members.s3xus.com/scenes/fff" }

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

        VCR.use_cassette("s3xus_index_search_by_actor#angel-youngs") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://members.s3xus.com/models/angel-youngs" }

      it "returns an array of expected_scenes", :aggregate_failures do
        expect(@result).to all(be_a(XXXDownload::Data::Scene))
        expect(@result).to all(have_attributes(lazy?: false))
        expect(@result).to all(have_attributes(video_link: start_with("https://www.s3xus.com/scenes/")))
        expect(@result).to all(have_attributes(downloading_links: be_a(XXXDownload::Data::StreamingLinks)))
      end
    end

    context "when actor does not exists" do
      before do
        # Comment this lines if you have live-credentials to a membership account
        # This will spawn the browser and ask the user for credentials
        allow(subject).to receive(:request_cookie).and_return(cookie_str)

        VCR.use_cassette("s3xus_index_search_by_actor#fff") do
          @result = subject.search_by_actor(resource)
        end
      end
      let(:resource) { "https://members.s3xus.com/models/fff" }

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

        VCR.use_cassette("s3xus_index_search_by_page#with_scenes") do
          @result = subject.search_by_page(resource)
        end
      end

      let(:resource) { "https://members.s3xus.com/scenes?page=2&order_by=publish_date&sort_by=desc" }

      it "returns an array of expected_scenes", :aggregate_failures do
        expect(@result).to all(be_a(XXXDownload::Data::Scene))
        expect(@result).to all(have_attributes(lazy?: true))
        expect(@result).to all(have_attributes(video_link: start_with("/scenes/")))
        expect(@result).to all(have_attributes(refresher: be_a(XXXDownload::Net::Refreshers::YppRefresh)))
      end
    end
  end
end
