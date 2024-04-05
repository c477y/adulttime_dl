# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::GoodpornIndex do
  subject { described_class.new }

  shared_examples "a successful search" do
    it "returns an array of Data::Scene objects" do
      expect(@result).to all(be_a(XXXDownload::Data::Scene))
    end

    it "returns scenes that are lazy" do
      expect(@result).to all(have_attributes(lazy?: true))
    end

    it "returns scenes with video_link" do
      expect(@result).to all(have_attributes(video_link: start_with("https://goodporn.to/videos/")))
    end

    it "returns scenes with a refresher of type XXXDownload::Net::Refreshers::GoodPorn" do
      expect(@result).to all(have_attributes(refresher: be_a(XXXDownload::Net::Refreshers::GoodPorn)))
    end
  end

  describe "#search_by_actor" do
    context "when actor exists" do
      before do
        VCR.use_cassette("goodporn_index_search_by_actor_name_success#kristen-price") do
          @result = subject.search_by_actor(resource)
        end
      end

      context "when actor name is passed" do
        let(:resource) { "Kirsten Price" }

        it_behaves_like "a successful search"
      end

      context "when actor URL is passed" do
        context "with trailing /" do
          let(:resource) { "https://goodporn.to/tags/kirsten-price/" }

          it_behaves_like "a successful search"
        end
        context "without trailing /" do
          let(:resource) { "https://goodporn.to/tags/kirsten-price" }

          it_behaves_like "a successful search"
        end
      end
    end

    context "when the actor does not exist" do
      let(:actor) { "fff" }

      before do
        VCR.use_cassette("goodporn_index_search_by_actor_failure#fff") do
          @result = subject.search_by_actor(actor)
        end
      end

      it "returns an empty array" do
        expect(@result).to eq([])
      end
    end
  end

  describe "#search_by_movie" do
    let(:movie) { "https://goodporn.to/channels/evil-angel/" }

    before do
      VCR.use_cassette("goodporn_index_search_by_movie_success#evil_angel") do
        @result = subject.search_by_movie(movie)
      end
    end

    it_behaves_like "a successful search"
  end
end
