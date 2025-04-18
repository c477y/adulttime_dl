# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::ManuelFerraraIndex, type: :file_support do
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
      expect(@result).to all(have_attributes(video_link: start_with("/scenes")))
    end

    it "returns scenes with a refresher of type XXXDownload::Net::Refreshers::JulesJordan" do
      expect(@result).to all(have_attributes(refresher: be_a(XXXDownload::Net::Refreshers::ManuelFerrara)))
    end
  end

  describe "#search_by_all_scenes" do
    context "when a scene exists" do
      before do
        VCR.use_cassette("manuel_ferrara/arabelle_raphael_anal") do
          @result = subject.search_by_all_scenes(resource)
        end
      end

      let(:resource) { "https://www.manuelferrara.com/trial/scenes/Arabelle-Raphael-Anal_vids.html" }

      let(:expected_scene) do
        {
          lazy: true,
          video_link: "/scenes/Arabelle-Raphael-Anal_vids.html"
        }
      end

      it "returns the expected scene data" do
        expect(@result.first.to_h).to include(expected_scene)
      end

      it_behaves_like "a successful search"
    end

    context "when a scene does not exist" do
      let(:resource) { "https://www.manuelferrara.com/trial/scenes/foo.html" }

      it "raises an error" do
        expect do
          VCR.use_cassette("manuel_ferrara/index_search_by_all_scenes#invalid_scene") do
            subject.search_by_all_scenes(resource)
          end
        end.to raise_error(XXXDownload::NotFoundError)
      end
    end
  end

  describe "#search_by_movie" do
    context "when the movie exists" do
      before do
        VCR.use_cassette("manuel_ferrara/index_search_by_movie#big_ass_tits") do
          @result = subject.search_by_movie(resource)
        end
      end

      let(:resource) { "https://www.manuelferrara.com/members/dvds/big-ass-tits.html" }

      let(:expected_scenes) do
        [
          "/scenes/Melina-Mason-Big-Tits-Big-Ass-Anal-Blowjob_vids.html",
          "/scenes/Kenzie-Taylor-Anal-Big-Tits-Facial-Lingerie-Blowjob_vids.html",
          "/scenes/Busty-Babe-Lena-Pauls-Big-Tits-Bounce-As-Manuel-Fucks-Her-Beautiful-Booty_vids.html",
          "/scenes/Ivy-Lebelle-Anal-Big-Tits-Big-Ass-Facial-Blowjob_vids.html"
        ]
      end

      it_behaves_like "a successful search"

      it "contains the expected scenes" do
        expect(@result.map(&:video_link)).to match(expected_scenes)
      end
    end

    context "when the movie does not exist" do
      let(:resource) { "https://www.manuelferrara.com/members/dvds/foo.html" }

      it "raises an error" do
        expect do
          VCR.use_cassette("manuel_ferrara/index_search_by_movie#invalid_movie") do
            @result = subject.search_by_movie(resource)
          end
        end.to raise_error(XXXDownload::NotFoundError)
      end
    end
  end

  describe "#search_by_actor" do
    context "when actor exists" do
      before do
        VCR.use_cassette("manuel_ferrara/index_search_by_actor#autumn_falls") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://manuelferrara.com/trial/models/autumn-falls.html" }

      it_behaves_like "a successful search"
    end

    context "when actor does not exists" do
      let(:resource) { "https://manuelferrara.com/trial/models/foo.html" }

      it "raises an error" do
        expect do
          VCR.use_cassette("manuel_ferrara/index_search_by_actor#fff") do
            @result = subject.search_by_actor(resource)
          end
        end.to raise_error(XXXDownload::NotFoundError)
      end
    end
  end

  describe "#search_by_page" do
    context "when page has scenes" do
      before do
        VCR.use_cassette("manuel_ferrara/index_search_by_page#with_scenes") do
          @result = subject.search_by_page(resource)
        end
      end

      let(:resource) { "https://manuelferrara.com/trial/categories/movies_1_d.html" }

      it_behaves_like "a successful search"
    end
  end

  describe "#actor_name" do
    context "when the actor exists: actor_name" do
      before do
        VCR.use_cassette("manuel_ferrara/actor_name#arabelle_raphael") do
          @result = subject.actor_name(resource)
        end
      end

      let(:resource) { "https://manuelferrara.com/trial/models/ArabelleRaphael.html" }

      it { expect(@result).to eq("Arabelle Raphael") }
    end

    context "when the actor does not exist" do
      let(:resource) { "https://manuelferrara.com/trial/models/foo.html" }

      it "raises an error" do
        expect do
          VCR.use_cassette("manuel_ferrara/actor_name/invalid_actor") do
            subject.actor_name(resource)
          end
        end.to raise_error(XXXDownload::NotFoundError)
      end
    end
  end
end
