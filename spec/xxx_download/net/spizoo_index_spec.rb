# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::SpizooIndex, type: :file_support do
  subject { described_class.new }

  include_context "config provider"

  let(:placeholder_cookie) { false }
  let(:cookie_str) { ENV.fetch("SPIZOO_COOKIE_STR", "cookie") }
  before do
    # Comment this line if you have live-credentials to a membership account
    # This will spawn the browser and ask the user for credentials
    allow(subject).to receive(:request_cookie).and_return(cookie_str)
  end

  shared_examples "a successful search" do
    it "returns an array of Data::Scene objects" do
      expect(@result).to all(be_a(XXXDownload::Data::Scene))
    end

    it "returns scenes that are lazy" do
      expect(@result).to all(have_attributes(lazy?: true))
    end

    it "returns scenes with video_link" do
      expect(@result).to all(have_attributes(video_link: start_with("/gallery.php")))
    end

    it "returns scenes with a refresher of type XXXDownload::Net::Refreshers::Spizoo" do
      expect(@result).to all(have_attributes(refresher: be_a(XXXDownload::Net::Refreshers::Spizoo)))
    end
  end

  describe "#search_by_all_scenes" do
    context "when a scene exists" do
      before do
        VCR.use_cassette("spizoo/index_search_by_all_scenes#kenzie_taylors_ex_boyfriend") do
          @result = subject.search_by_all_scenes(resource)
        end
      end

      let(:resource) { "https://www.spizoo.com/members/gallery.php?id=2449&type=vids" }

      let(:expected_scene) do
        {
          lazy: true,
          video_link: "/gallery.php?id=2449&type=vids"
        }
      end

      it "returns the expected scene data" do
        expect(@result.first.to_h).to include(expected_scene)
      end

      it_behaves_like "a successful search"
    end

    context "when a scene does not exist" do
      let(:resource) { "https://www.spizoo.com/members/gallery.php?id=ffff&type=vids" }

      it "raises an error" do
        expect do
          VCR.use_cassette("spizoo/index_search_by_all_scenes#invalid_scene") do
            @result = subject.search_by_all_scenes(resource)
          end
        end.to raise_error(XXXDownload::NotFoundError)
      end
    end
  end

  describe "#search_by_actor" do
    context "when actor exists : jennifer mendez" do
      before do
        VCR.use_cassette("spizoo/index_search_by_actor#jennifer_mendez") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://www.spizoo.com/members/sets.php?id=2221" }

      it_behaves_like "a successful search"

      it { expect(@result.length).to be >= 2 }
    end

    context "when actor exists : kenzie taylor" do
      before do
        VCR.use_cassette("spizoo/index_search_by_actor#kenzie_taylor") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://www.spizoo.com/members/sets.php?id=490" }

      it_behaves_like "a successful search"

      it { expect(@result.length).to be >= 10 }
    end

    context "when actor exists : sasha rose" do
      before do
        VCR.use_cassette("spizoo/index_search_by_actor#sasha_rose") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://www.spizoo.com/members/sets.php?id=2061" }

      it_behaves_like "a successful search"

      it { expect(@result.length).to be >= 1 }
    end

    context "when actor does not exists" do
      before do
        VCR.use_cassette("spizoo/index_search_by_actor#fff") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://www.spizoo.com/members/sets.php?id=fff" }

      it "returns an empty array", :aggregate_failures do
        expect(@result).to be_empty
      end
    end
  end

  describe "#search_by_page" do
    context "when page has scenes" do
      before do
        VCR.use_cassette("spizoo/index_search_by_page#with_scenes") do
          @result = subject.search_by_page(resource)
        end
      end

      let(:resource) { "https://www.spizoo.com/members/category.php?id=437&page=1&s=d" }

      it_behaves_like "a successful search"

      it { expect(@result.length).to eq(20) }
    end
  end

  describe "#actor_name" do
    context "when the actor exists: actor_name" do
      before do
        VCR.use_cassette("spizoo/index_search_by_actor#kenzie_taylor") do
          @result = subject.actor_name(resource)
        end
      end

      let(:resource) { "https://www.spizoo.com/members/sets.php?id=490" }

      it { expect(@result).to eq("Kenzie Taylor") }
    end

    context "when the actor does not exist" do
      before do
        VCR.use_cassette("spizoo/index_search_by_actor#fff") do
          @result = subject.actor_name(resource)
        end
      end

      let(:resource) { "https://www.spizoo.com/members/sets.php?id=fff" }

      it { expect(@result).to be_nil }
    end
  end
end
