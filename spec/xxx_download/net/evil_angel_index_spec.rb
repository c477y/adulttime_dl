# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::EvilAngelIndex, type: :file_support do
  subject { described_class.new }

  include_context "config provider"
  let(:site) { "evilangel" }

  describe "#search_by_actor" do
    context "when the actor exists: samantha saint" do
      before do
        VCR.use_cassette("evil_angel/search_by_actor#samantha_saint") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://www.evilangel.com/en/pornstar/view/Samantha-Saint/16653" }

      it { expect(@result).to all(be_a(XXXDownload::Data::Scene)) }
      it { expect(@result.length).to be > 0 }
      it { expect(@result).to all(have_attributes(clip_id: instance_of(Integer))) }
      it { expect(@result).to all(have_attributes(video_link: start_with("https://www.evilangel.com/en/video/evilangel"))) }
    end

    context "when actor name is provided: samantha saint" do
      before do
        VCR.use_cassette("evil_angel/search_by_actor#samantha_saint") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "Samantha Saint" }

      it { expect(@result).to all(be_a(XXXDownload::Data::Scene)) }
      it { expect(@result.length).to be > 0 }
      it { expect(@result).to all(have_attributes(clip_id: instance_of(Integer))) }
      it { expect(@result).to all(have_attributes(video_link: start_with("https://www.evilangel.com/en/video/evilangel"))) }
    end

    context "when the actor exists: ramon nomar" do
      before do
        VCR.use_cassette("evil_angel/search_by_actor#ramon_nomar") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://www.evilangel.com/en/pornstar/view/Ramon-Nomar/8622" }

      it { expect(@result).to all(be_a(XXXDownload::Data::Scene)) }
      it { expect(@result.length).to be > 0 }
      it { expect(@result).to all(have_attributes(clip_id: instance_of(Integer))) }
      it { expect(@result).to all(have_attributes(video_link: start_with("https://www.evilangel.com/en/video/evilangel"))) }
    end

    context "when actor does not exists" do
      before do
        VCR.use_cassette("evil_angel/search_by_actor#invalid_actor_fff") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://www.evilangel.com/en/pornstar/view/fff/fff" }

      it "returns an empty array", :aggregate_failures do
        expect(@result).to be_empty
      end
    end
  end

  describe "#search_by_movie" do
    context "when the movie exists: alien ass party 02" do
      before do
        VCR.use_cassette("evil_angel/search_by_movie#alien_ass_party_02") do
          @result = subject.search_by_movie(resource)
        end
      end

      let(:resource) { "https://www.evilangel.com/en/movie/Alien-Ass-Party-02/25283" }

      it { expect(@result).to all(be_a(XXXDownload::Data::Scene)) }
      it { expect(@result.length).to eq(6) }
      it { expect(@result).to all(have_attributes(clip_id: instance_of(Integer))) }
      it { expect(@result).to all(have_attributes(video_link: start_with("https://www.evilangel.com/en/video/evilangel"))) }
    end

    context "when the movie exists: stunning curves" do
      before do
        VCR.use_cassette("evil_angel/search_by_movie#stunning_curves") do
          @result = subject.search_by_movie(resource)
        end
      end

      let(:resource) { "https://www.evilangel.com/en/movie/Stunning-Curves/28128" }

      it { expect(@result).to all(be_a(XXXDownload::Data::Scene)) }
      it { expect(@result.length).to eq(8) }
      it { expect(@result).to all(have_attributes(clip_id: instance_of(Integer))) }
      it { expect(@result).to all(have_attributes(video_link: start_with("https://www.evilangel.com/en/video/evilangel"))) }
    end

    context "when the movie exists: trans international las vegas" do
      before do
        VCR.use_cassette("evil_angel/search_by_movie#trans_international_las_vegas") do
          @result = subject.search_by_movie(resource)
        end
      end

      let(:resource) { "https://members.evilangel.com/en/movie/Trans-International-Las-Vegas/83477" }

      it { expect(@result).to all(be_a(XXXDownload::Data::Scene)) }
      it { expect(@result.length).to eq(8) }
      it { expect(@result).to all(have_attributes(clip_id: instance_of(Integer))) }
      it { expect(@result).to all(have_attributes(video_link: start_with("https://www.evilangel.com/en/video/evilangel"))) }

      it "all scenes have a trans actor" do
        expect(@result.all? { |scene| scene.respond_to?(:trans?) }).to be true
      end
    end

    context "when movie does not exists" do
      before do
        VCR.use_cassette("evil_angel/search_by_movie#valid_movie_xyz") do
          @result = subject.search_by_movie(resource)
        end
      end

      let(:resource) { "https://www.evilangel.com/en/movie/fff/fff" }

      it { expect(@result).to be_empty }
    end
  end
end
