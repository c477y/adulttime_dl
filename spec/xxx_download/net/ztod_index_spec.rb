# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::ZtodIndex, type: :file_support do
  subject { described_class.new }

  include_context "config provider"
  let(:site) { "ztod" }
  let(:placeholder_cookie) { false }

  describe "#search_by_actor" do
    context "when the actor exists" do
      before do
        VCR.use_cassette("ztod_index_search_by_all_scenes#valid_actor_Keira-Croft") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://members.zerotolerancefilms.com/en/pornstar/view/Keira-Croft/86891" }

      it { expect(@result).to all(be_a(XXXDownload::Data::Scene)) }
      it { expect(@result.length).to be > 10 }
      it { expect(@result).to all(have_attributes(clip_id: instance_of(Integer))) }
      it { expect(@result).to all(have_attributes(video_link: start_with("https://www.zerotolerancefilms.com/en/video"))) }
    end

    context "when actor does not exists" do
      before do
        VCR.use_cassette("ztod_index_search_by_all_scenes#invalid_actor_fff") do
          @result = subject.search_by_actor(resource)
        end
      end

      let(:resource) { "https://members.zerotolerancefilms.com/en/pornstar/view/fff/123" }

      it "returns an empty array", :aggregate_failures do
        expect(@result).to be_empty
      end
    end
  end

  describe "#search_by_movie" do
    context "when the movie exists" do
      before do
        VCR.use_cassette("ztod_index_search_by_movie#valid_movie_wet-dreams-cum-true-6") do
          @result = subject.search_by_movie(resource)
        end
      end

      let(:resource) { "https://members.zerotolerancefilms.com/en/movie/wet-dreams-cum-true-6/80348" }

      it { expect(@result).to all(be_a(XXXDownload::Data::Scene)) }
      it { expect(@result.length).to eq(4) }
      it { expect(@result).to all(have_attributes(clip_id: instance_of(Integer))) }
      it { expect(@result).to all(have_attributes(video_link: start_with("https://www.zerotolerancefilms.com/en/video"))) }
    end

    context "when movie does not exists" do
      before do
        VCR.use_cassette("ztod_index_search_by_movie#valid_movie_xyz") do
          @result = subject.search_by_movie(resource)
        end
      end

      let(:resource) { "https://members.zerotolerancefilms.com/en/movie/xxx/123" }

      it { expect(@result).to be_empty }
    end
  end
end
