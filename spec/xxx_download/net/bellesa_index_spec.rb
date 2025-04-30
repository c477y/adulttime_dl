# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::BellesaIndex, type: :file_support do
  subject { described_class.new }

  include_context "config provider"

  shared_examples "a successful search" do
    it "returns an array of Data::Scene objects" do
      expect(@result).to all(be_a(XXXDownload::Data::Scene))
    end

    it "returns scenes that are lazy" do
      expect(@result).to all(have_attributes(lazy?: true))
    end

    it "returns scenes with video_link" do
      expect(@result).to all(have_attributes(video_link: start_with("/path")))
    end

    it "returns scenes with a refresher of type XXXDownload::Net::Refreshers::Bellesa" do
      expect(@result).to all(have_attributes(refresher: be_a(XXXDownload::Net::Refreshers::Bellesa)))
    end
  end

  describe "#search_by_all_scenes" do
    context "when a scene exists" do
      before do
        VCR.use_cassette("bellesa/index_search_by_all_scenes#valid_scene") do
          @result = subject.search_by_all_scenes(resource)
        end
      end

      let(:resource) { "YOUR_TEST_RESOURCE" }

      let(:expected_scene) do
        {}
      end
      let(:download_link_keys) { %i[res_2160p res_1080p res_270p default] }

      it "returns the expected scene data", :aggregate_failures do
        expect(@result.length).to eq(1)
        expect(@result.first).to be_a(XXXDownload::Data::Scene)
        expect(@result.first.to_h).to include(expected_scene)

        # Uncomment these if your scene is lazy
        # expect(@result).to all(have_attributes(lazy?: true))
        # expect(@result).to all(have_attributes(refresher: be_a(XXXDownload::Net::Refreshers::Bellesa)))

        # Uncomment these if your scene is not lazy
        # expect(@result.first.downloading_links).to be_a(XXXDownload::Data::StreamingLinks)
        # expect(@result.first.downloading_links.to_h.keys).to match_array(download_link_keys)
      end
    end

    context "when a scene does not exist" do
      before do
        VCR.use_cassette("bellesa/index_search_by_all_scenes#invalid_scene") do
          @result = subject.search_by_all_scenes(resource)
        end
      end

      let(:resource) { "YOUR_TEST_RESOURCE" }

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

      let(:resource) { "YOUR_TEST_RESOURCE" }

      let(:expected_scene) do
        {}
      end
      let(:download_link_keys) { %i[res_2160p res_1080p res_270p default] }

      it "returns the expected scene data", :aggregate_failures do
        expect(@result.length).to eq(1)
        expect(@result.first).to be_a(XXXDownload::Data::Scene)
        expect(@result.first.to_h).to include(expected_scene)

        # Uncomment these if your scene is lazy
        # expect(@result).to all(have_attributes(lazy?: true))
        # expect(@result).to all(have_attributes(refresher: be_a(XXXDownload::Net::Refreshers::Bellesa)))

        # Uncomment these if your scene is not lazy
        # expect(@result.first.downloading_links).to be_a(XXXDownload::Data::StreamingLinks)
        # expect(@result.first.downloading_links.to_h.keys).to match_array(download_link_keys)
      end
    end

    context "when the movie does not exist" do
      before do
        VCR.use_cassette("bellesa/index_search_by_movie#invalid_movie") do
          @result = subject.search_by_movie(resource)
        end
      end

      let(:resource) { "YOUR_TEST_RESOURCE" }

      it "returns the expected scene data" do
        expect(@result.length).to eq(0)
      end
    end
  end

  describe "#search_by_actor" do
    context "when actor exists" do
      before do
        VCR.use_cassette("bellesa/index_search_by_actor#angel-youngs") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "YOUR_TEST_RESOURCE" }

      it "returns an array of expected_scenes", :aggregate_failures do
        expect(@result).to all(be_a(XXXDownload::Data::Scene))
        expect(@result).to all(have_attributes(lazy?: false))
        expect(@result).to all(have_attributes(video_link: start_with("XYZ")))
        expect(@result).to all(have_attributes(downloading_links: be_a(XXXDownload::Data::StreamingLinks)))
      end
    end

    context "when actor does not exists" do
      before do
        VCR.use_cassette("bellesa/index_search_by_actor#fff") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "YOUR_TEST_RESOURCE" }

      it "returns an empty array", :aggregate_failures do
        expect(@result).to be_empty
      end
    end
  end

  describe "#search_by_page" do
    context "when page has scenes" do
      before do
        VCR.use_cassette("bellesa/index_search_by_page#with_scenes") do
          @result = subject.search_by_page(resource)
        end
      end

      let(:resource) { "YOUR_TEST_RESOURCE" }

      it "returns an array of expected_scenes", :aggregate_failures do
        expect(@result).to all(be_a(XXXDownload::Data::Scene))
        expect(@result).to all(have_attributes(lazy?: true))
        expect(@result).to all(have_attributes(video_link: start_with("XYZ")))
        expect(@result).to all(have_attributes(refresher: be_a(XXXDownload::Net::Refreshers::BellesaRefresh)))
      end
    end
  end

  describe "#actor_name" do
    context "when the actor exists: actor_name" do
      before do
        VCR.use_cassette("bellesa/actor_name#valid_actor") do
          @result = subject.actor_name(resource)
        end
      end

      let(:resource) { "YOUR_TEST_RESOURCE" }

      it { expect(@result).to eq("Value") }
    end

    context "when the actor does not exist" do
      before do
        VCR.use_cassette("bellesa/actor_name/invalid_actor") do
          @result = subject.actor_name(resource)
        end
      end

      let(:resource) { "YOUR_TEST_RESOURCE" }

      it { expect(@result).to be_nil }
    end
  end
end
