# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Data::BellesaApiScene do
  subject(:bellesa_api_scene) { described_class.new(attributes) }

  let(:attributes) do
    {
      id: 1,
      title: "Scene Title",
      tags: %w[Tag1 Tag2],
      source: "source_file",
      resolutions: %w[360 720],
      duration: 90,
      posted_on: Time.now.to_i,
      content_provider: [{ name: "Bellesa" }],
      performers: [{ name: "Actor1" }, { name: "Actor2" }]
    }
  end

  describe "#to_scene" do
    subject(:scene) { bellesa_api_scene.to_scene }

    it { expect(scene).to be_a(XXXDownload::Data::Scene) }
    it { expect(scene.video_link).to eq("https://bellesaplus.co/videos/1/scene-title") }
    it { expect(scene.title).to eq(attributes[:title]) }
    it { expect(scene.actors.map(&:name)).to match_array(%w[Actor1 Actor2]) }
    it { expect(scene.network_name).to eq("Bellesa") }
    it { expect(scene.tags).to eq(bellesa_api_scene.tags) }
    it { expect(scene.duration).to eq("01:30") }
    it { expect(scene.release_date).to match(/\d{4}-\d{2}-\d{2}/) }
    it { expect(scene.download_sizes).to match_array(%w[360 720]) }

    it "creates the download links" do
      expected_links = {
        res_360p: "https://s.bellesa.co/v/source_file/360.mp4",
        res_720p: "https://s.bellesa.co/v/source_file/720.mp4",
        default: [
          "https://s.bellesa.co/v/source_file/360.mp4",
          "https://s.bellesa.co/v/source_file/720.mp4"
        ]
      }
      expect(scene.downloading_links.to_h).to eq(expected_links)
    end

    it { expect(scene.lazy).to eq(false) }
  end

  describe "validation" do
    context "when source is missing" do
      before { attributes.delete(:source) }

      it { expect { bellesa_api_scene.to_scene }.to raise_error(XXXDownload::Data::BellesaApiScene::NoSourceError) }
    end
  end
end
