# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::JulesJordanIndex do
  # include_context "config provider"
  #
  # let(:placeholder_cookie) { false }
  # let(:cookie_str) { ENV.fetch("JULES_JORDAN_COOKIE_STR", "cookie") }
  # before { allow(XXXDownload.config).to receive(:cookie).and_return(cookie_str) }

  subject { described_class.new }

  shared_examples "a successful search" do
    it "returns an array of Data::Scene objects" do
      expect(@result).to all(be_a(XXXDownload::Data::Scene))
    end

    it "returns scenes that are lazy" do
      expect(@result).to all(have_attributes(lazy?: true))
    end

    it "returns scenes with video_link" do
      expect(@result).to all(have_attributes(video_link: start_with("/scenes")))
    end

    it "returns scenes with a refresher of type XXXDownload::Net::Refreshers::JulesJordan" do
      expect(@result).to all(have_attributes(refresher: be_a(XXXDownload::Net::Refreshers::JulesJordan)))
    end
  end

  describe "#search_by_all_scenes" do
    context "when a scene exists" do
      before do
        VCR.use_cassette("jules_jordan/emily_norman_interracial_big_tits") do
          @result = subject.search_by_all_scenes(resource)
        end
      end

      let(:resource) { "https://www.julesjordan.com/members/scenes/Emily-Norman-Interracial-Big-Tits_vids.html" }
      let(:expected_scene) do
        {
          lazy: true,
          video_link: "/scenes/Emily-Norman-Interracial-Big-Tits_vids.html"
        }
      end

      it "returns the expected scene data" do
        expect(@result.first.to_h).to include(expected_scene)
      end

      it_behaves_like "a successful search"
    end

    context "when a scene does not exist" do
      let(:resource) { "https://www.julesjordan.com/members/scenes/foo.html" }

      it "raises an error" do
        expect do
          VCR.use_cassette("jules_jordan/invalid_scene") do
            subject.search_by_all_scenes(resource)
          end
        end.to raise_error(XXXDownload::NotFoundError)
      end
    end
  end

  describe "#search_by_movie" do
    context "when a movie exists" do
      before do
        VCR.use_cassette("jules_jordan/super_stacked_3") do
          @result = subject.search_by_movie(resource)
        end
      end

      let(:resource) { "https://www.julesjordan.com/members/dvds/Super-Stacked-3.html" }

      let(:expected_scenes) do
        [
          "/scenes/Lily-Lou-Has-Her-Ass-Explored_vids.html",
          "/scenes/Manuel-Goes-On-An-Expedition-Into-Kylie-Pages-Amazing-Curves_vids.html",
          "/scenes/Emma-Magnolia-Big-Butt_vids.html",
          "/scenes/Xwife-Karen-Latina-Big-Tits_vids.html"
        ]
      end

      it_behaves_like "a successful search"

      it "contains the expected scenes" do
        expect(@result.map(&:video_link)).to match(expected_scenes)
      end
    end

    context "when a movie does not exist" do
      let(:resource) { "https://www.julesjordan.com/members/dvds/foo.html" }

      it "raises an error" do
        expect do
          VCR.use_cassette("jules_jordan/invalid_movie") do
            subject.search_by_movie(resource)
          end
        end.to raise_error(XXXDownload::NotFoundError)
      end
    end
  end

  describe "#search_by_actor" do
    context "when a actor exists" do
      before do
        VCR.use_cassette("jules_jordan/angela_white") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://www.julesjordan.com/trial/models/angela-white.html" }

      it_behaves_like "a successful search"
    end

    context "when a actor does not exist" do
      let(:resource) { "https://www.julesjordan.com/trial/models/foo.html" }

      it "raises an error" do
        expect do
          VCR.use_cassette("jules_jordan/invalid_actor") do
            subject.search_by_actor(resource)
          end
        end.to raise_error(XXXDownload::NotFoundError)
      end
    end
  end

  describe "#search_by_page" do
    context "when the page contains scenes" do
      before do
        VCR.use_cassette("jules_jordan/search_by_page1") do
          @result = subject.search_by_page(resource)
        end
      end

      let(:resource) { "https://www.julesjordan.com/trial/categories/movies_1_d.html" }

      it_behaves_like "a successful search"
    end
  end

  describe "#actor_name" do
    context "when the actor exists: angela white" do
      before do
        VCR.use_cassette("jules_jordan/angela_white") do
          @result = subject.actor_name(resource)
        end
      end

      let(:resource) { "https://www.julesjordan.com/trial/models/angela-white.html" }

      it { expect(@result).to eq("Angela White") }
    end

    context "when the actor exists: angela white" do
      before do
        VCR.use_cassette("jules_jordan/nacho_vidal") do
          @result = subject.actor_name(resource)
        end
      end

      let(:resource) { "https://www.julesjordan.com/trial/models/nacho-vidal.html" }

      it { expect(@result).to eq("Nacho Vidal") }
    end

    context "when the actor does not exist" do
      before do
        VCR.use_cassette("jules_jordan/super_stacked_3") do
          @result = subject.actor_name(resource)
        end
      end

      let(:resource) { "https://www.julesjordan.com/members/dvds/Super-Stacked-3.html" }

      it { expect(@result).to be_nil }
    end
  end
end
