# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::NewSensationsIndex, type: :file_support do
  subject { described_class.new }

  include_context "config provider"
  let(:override_cookie) do
    { "domain" => ".newsensations.com", "cookie" => ENV.fetch("NEW_SENSATIONS_COOKIE_STR", "cookie") }
  end

  # Don't set up browser
  before do
    allow_any_instance_of(described_class).to receive(:start_browser).and_return("stubbed")
    allow(subject).to receive(:fetch).and_return(nil)
  end

  describe "#search_by_all_scenes" do
    context "when a scene exists" do
      let(:resource) { "https://newsensations.com/members/gallery.php?id=7718&type=vids" }
      let(:result) { subject.search_by_all_scenes(resource) }

      it "returns the expected scene data", :aggregate_failures do
        expect(result.length).to eq(1)
        expect(result.first).to be_a(XXXDownload::Data::Scene)
        expect(result).to all(have_attributes(lazy?: true))
        expect(result).to all(have_attributes(refresher: be_a(XXXDownload::Net::Refreshers::NewSensations)))
      end
    end
  end

  describe "#search_by_actor" do
    context "when actor exists" do
      let(:resource) { "https://newsensations.com/members/sets.php?id=3037" }
      let(:result) { subject.search_by_actor(resource) }

      it "returns an array of expected_scenes", :aggregate_failures do
        pending "Only works with live-credentials"

        expect(result).to all(be_a(XXXDownload::Data::Scene))
        expect(result).to all(have_attributes(lazy?: true))
        expect(result).to all(have_attributes(video_link: start_with("/gallery.php")))
      end
    end
  end

  describe "#actor_name" do
    context "when the actor exists: Ashlynn Brooke" do
      let(:resource) { "https://newsensations.com/members/sets.php?id=412" }

      it "returns the actor name" do
        pending "Only works with live-credentials"

        expect(subject.actor_name(resource)).to eq("Ashlynn Brooke")
      end
    end
  end
end
