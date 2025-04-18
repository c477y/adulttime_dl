# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::PornfidelityIndex, type: :file_support do
  subject { described_class.new }

  include_context "config provider"
  let(:override_cookie) do
    { "domain" => ".kellymadisonmedia.com", "cookie" => ENV.fetch("PORNFIDELITY_COOKIE_STR", "cookie") }
  end

  # Don't set up browser
  before do
    allow_any_instance_of(described_class).to receive(:start_browser).and_return(nil)
    allow_any_instance_of(described_class).to receive(:load_interceptor).and_return(nil)
  end

  describe "#search_by_all_scenes" do
    context "when a scene exists" do
      before do
        allow(subject).to receive(:fetch).and_return(XXXDownload::Data::Scene.new(expected_scene))
        @result = subject.search_by_all_scenes(resource)
      end

      let(:resource) { "https://members.kellymadisonmedia.com/episodes/1059885594" }

      let(:expected_scene) do
        {
          lazy: false,
          video_link: "https://members.kellymadisonmedia.com/episodes/1059885594",
          title: "Pay to Play",
          actors: [{ name: "Madison", gender: "unknown" },
                   { name: "Payton Preslee", gender: "unknown" }],
          network_name: "Pornfidelity",
          collection_tag: "PF",
          release_date: "2025-03-14",
          downloading_links: { default: ["https://content-cdn.kellymadisonmedia.com/"] }
        }
      end

      it "returns the expected scene data", :aggregate_failures do
        expect(@result.length).to eq(1)
        expect(@result.first).to be_a(XXXDownload::Data::Scene)
        expect(@result.first.to_h).to include(expected_scene)
        expect(@result.first.downloading_links).to be_a(XXXDownload::Data::StreamingLinks)
      end
    end

    context "when a scene does not exist" do
      before do
        allow(subject).to receive(:fetch).and_return(nil)
        @result = subject.search_by_all_scenes(resource)
      end

      let(:resource) { "https://members.kellymadisonmedia.com/episodes/1059885594" }

      it "returns the expected scene data" do
        expect(@result.length).to eq(0)
      end
    end
  end

  describe "#search_by_actor" do
    context "when actor exists" do
      let(:resource) { "https://members.kellymadisonmedia.com/models/brooke-wylde" }

      it "returns an array of expected_scenes", :aggregate_failures do
        pending "Only works with live-credentials"

        @result = subject.search_by_actor(resource)
        expect(@result).to all(be_a(XXXDownload::Data::Scene))
        expect(@result).to all(have_attributes(lazy?: false))
        expect(@result).to all(have_attributes(video_link: start_with("https://members.kellymadisonmedia.com/")))
        expect(@result).to all(have_attributes(downloading_links: be_a(XXXDownload::Data::StreamingLinks)))
      end
    end
  end

  describe "#actor_name" do
    let(:examples) do
      [
        { url: "https://members.kellymadisonmedia.com/models/breena", expected: "Breena" },
        { url: "https://members.kellymadisonmedia.com/models/brenna-sparks", expected: "Brenna Sparks" },
        { url: "https://members.kellymadisonmedia.com/models/brett-rossi", expected: "Brett Rossi" },
        { url: "https://members.kellymadisonmedia.com/models/briana-banks", expected: "Briana Banks" },
        { url: "https://members.kellymadisonmedia.com/models/briana-blair", expected: "Briana Blair" },
        { url: "https://members.kellymadisonmedia.com/models/bridgette-b", expected: "Bridgette B" },
        { url: "https://members.kellymadisonmedia.com/models/brittney-skye", expected: "Brittney Skye" },
        { url: "https://members.kellymadisonmedia.com/models/brooke-banks", expected: "Brooke Banks" }
      ]
    end

    it "returns the expected actor name" do
      examples.each do |ex|
        actual = subject.actor_name(ex[:url])
        expect(actual).to eq(ex[:expected]), "For url `#{ex[:url]}` Expected: #{ex[:expected]}, got: #{actual}"
      end
    end
  end
end
