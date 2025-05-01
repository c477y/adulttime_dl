# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::BellesaIndex, type: :file_support do
  subject { described_class.new }

  include_context "config provider"
  let(:cookie_str) { ENV.fetch("BELLESA_COOKIE_STR", "cookie") }

  before do
    # Comment these lines if you have live-credentials to a membership account
    # This will spawn the browser and ask the user for credentials
    authenticator = subject.send(:authenticator)
    allow(authenticator).to receive(:request_cookie).and_return(cookie_str)
  end

  describe "#search_by_all_scenes" do
    context "when a scene exists" do
      before do
        VCR.use_cassette("bellesa/index_search_by_all_scenes#valid_scene") do
          @result = subject.search_by_all_scenes(resource)
        end
      end

      let(:resource) { "https://bellesaplus.co/videos/10931/episode-129-chantal-quinton" }
      let(:expected_scene) do
        {
          lazy: false,
          video_link: "https://bellesaplus.co/videos/10931/episode-129-chantal-quinton",
          title: "Episode 129: Chantal & Quinton",
          actors: [
            { name: "Chantal Danielle", gender: "unknown" },
            { name: "Quinton James", gender: "unknown" }
          ],
          network_name: "Bellesa Blind Date",
          collection_tag: "C",
          duration: "35:33",
          release_date: "2025-03-28",
          download_sizes: %w[360 480 720 1080 1440 2160]
        }
      end

      let(:download_link_keys) { %i[res_2160p res_1080p res_720p res_480p res_360p default] }

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
        VCR.use_cassette("bellesa/index_search_by_all_scenes#invalid_scene") do
          @result = subject.search_by_all_scenes(resource)
        end
      end

      let(:resource) { "https://bellesaplus.co/videos/0/xyz" }

      it "returns the expected scene data" do
        expect(@result.length).to eq(0)
      end
    end
  end

  describe "#search_by_movie" do
    context "when the movie exists" do
      before do
        VCR.use_cassette("bellesa/index_search_by_movie#valid_movie") do
          @result = subject.search_by_movie(resource)
        end
      end

      let(:resource) { "https://bellesaplus.co/videos?providers=belle-says" }

      it "returns the expected scene data", :aggregate_failures do
        expect(@result.length).to be > 1
        expect(@result).to all(be_a(XXXDownload::Data::Scene))
        expect(@result).to all(have_attributes(lazy?: false))
        expect(@result).to all(have_attributes(video_link: start_with("https://bellesaplus.co/videos/")))
        expect(@result).to all(have_attributes(downloading_links: be_a(XXXDownload::Data::StreamingLinks)))
      end
    end

    context "when the movie does not exist" do
      before do
        VCR.use_cassette("bellesa/index_search_by_movie#invalid_movie") do
          @result = subject.search_by_movie(resource)
        end
      end

      let(:resource) { "https://bellesaplus.co/videos?providers=foo" }

      it "returns the expected scene data" do
        expect(@result.length).to eq(0)
      end
    end
  end

  describe "#search_by_actor" do
    context "when actor exists" do
      before do
        VCR.use_cassette("bellesa/index_search_by_actor#chantal-danielle") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://bellesaplus.co/videos?performers=chantal-danielle" }

      it "returns an array of expected_scenes", :aggregate_failures do
        expect(@result).to all(be_a(XXXDownload::Data::Scene))
        expect(@result).to all(have_attributes(lazy?: false))
        expect(@result).to all(have_attributes(video_link: start_with("https://bellesaplus.co/videos/")))
        expect(@result).to all(have_attributes(downloading_links: be_a(XXXDownload::Data::StreamingLinks)))
      end
    end

    context "when actor does not exists" do
      before do
        VCR.use_cassette("bellesa/index_search_by_actor#fff") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://bellesaplus.co/videos?performers=fff" }

      it "returns an empty array", :aggregate_failures do
        expect(@result).to be_empty
      end
    end
  end

  describe "#actor_name" do
    context "when the actor exists: actor_name" do
      let(:resource) { "https://bellesaplus.co/videos?performers=chantal-danielle" }

      it { expect(subject.actor_name(resource)).to eq("Chantal Danielle") }
    end

    context "when the actor does not exist" do
      let(:resource) { "https://bellesaplus.co/videos?performers=" }

      it { expect { subject.actor_name(resource) }.to raise_error(/Unable to extract performers from/) }
    end
  end
end
