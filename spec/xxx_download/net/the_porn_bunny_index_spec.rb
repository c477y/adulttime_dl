# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::ThePornBunnyIndex, type: :file_support do
  subject { described_class.new }

  include_context "config provider"

  describe "#search_by_all_scenes" do
    context "when a scene exists" do
      let(:result) { subject.search_by_all_scenes(resource) }
      let(:resource) { "https://www.thepornbunny.com/video/stuck-and-sucked/" }

      it "returns the expected scene data", :aggregate_failures do
        expect(result.length).to eq(1)
        expect(result.first).to be_a(XXXDownload::Data::Scene)
        expect(result).to all(have_attributes(lazy?: true))
        expect(result).to all(have_attributes(refresher: be_a(XXXDownload::Net::Refreshers::ThePornBunny)))
      end
    end
  end

  describe "#search_by_actor" do
    context "when actor exists: alexis fawx" do
      before do
        VCR.use_cassette("thepornbunny_index_search_by_actor#alexis-fawx") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://www.thepornbunny.com/pornstar/alexis-fawx/" }

      it "returns an array of expected_scenes", :aggregate_failures do
        expect(@result.length).to be > 10
        expect(@result.first).to be_a(XXXDownload::Data::Scene)
        expect(@result).to all(have_attributes(lazy?: true))
        expect(@result).to all(have_attributes(refresher: be_a(XXXDownload::Net::Refreshers::ThePornBunny)))
      end
    end

    context "when actor exists: raven bay" do
      before do
        VCR.use_cassette("thepornbunny_index_search_by_actor#raven-bay") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://www.thepornbunny.com/pornstar/raven-bay/" }

      it "returns an array of expected_scenes", :aggregate_failures do
        expect(@result.length).to be > 1
        expect(@result.first).to be_a(XXXDownload::Data::Scene)
        expect(@result).to all(have_attributes(lazy?: true))
        expect(@result).to all(have_attributes(refresher: be_a(XXXDownload::Net::Refreshers::ThePornBunny)))
      end
    end

    context "when actor does not exists" do
      before do
        VCR.use_cassette("thepornbunny_index_search_by_actor#fff") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://www.thepornbunny.com/pornstar/fff/" }

      it "returns an empty array", :aggregate_failures do
        expect(@result).to be_empty
      end
    end
  end

  describe "#actor_name" do
    context "when the actor exists: actor_name" do
      let(:test_cases) do
        {
          "https://www.thepornbunny.com/pornstar/abella-danger" => "Abella Danger",
          "https://www.thepornbunny.com/pornstar/angela-white" => "Angela White",
          "https://www.thepornbunny.com/pornstar/johnny-sins" => "Johnny Sins",
          "https://www.thepornbunny.com/pornstar/autumn-falls" => "Autumn Falls"
        }
      end

      it "returns correct actor names" do
        test_cases.each do |resource, expected_name|
          expect(subject.actor_name(resource)).to eq(expected_name)
        end
      end
    end

    context "when invalid URL" do
      let(:result) { subject.actor_name(resource) }

      let(:resource) { "http" }

      it { expect { result }.to raise_error(URI::InvalidURIError, "Invalid URL: missing scheme or host") }
    end
  end
end
