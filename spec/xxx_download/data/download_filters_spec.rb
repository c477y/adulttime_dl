# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Data::DownloadFilters do
  subject { described_class.new(attributes) }
  let(:attributes) do
    {
      skip_studios: [],
      skip_performers: [],
      skip_lesbian: false,
      skip_trans: true,
      skip_keywords: [],
      oldest_year: 2010,
      minimum_duration: "10:00",
      **attr_overrides
    }
  end
  let(:overrides) { {} }
  let(:attr_overrides) { {} }

  describe "#skip?" do
    let(:scene) do
      XXXDownload::Data::Scene.new(
        lazy: false,
        video_link: "https://example.com",
        network_name: "Test Network",
        actors: [],
        title: "Test Title",
        release_date: "2023-01-01",
        file_name: "test_file",
        **overrides
      )
    end

    context "when scene is lesbian and skip_lesbian is true" do
      let(:attr_overrides) { { skip_lesbian: true } }
      let(:overrides) { { actors: [{ name: "F", gender: "female" }] } }

      it "returns true" do
        expect(subject.skip?(scene)).to be true
      end
    end

    context "when scene has trans performers and skip_trans is true" do
      let(:attr_overrides) { { skip_trans: true } }
      let(:overrides) { { actors: [{ name: "T", gender: "shemale" }] } }

      it "returns true" do
        expect(subject.skip?(scene)).to be true
      end
    end

    context "when scene's network is in skip_studios" do
      let(:attr_overrides) { { skip_studios: ["Test Network"] } }

      it "returns true" do
        expect(subject.skip?(scene)).to be true
      end
    end

    context "when scene has a performer in skip_performers" do
      let(:attr_overrides) { { skip_performers: ["Test Actor"] } }
      let(:overrides) { { actors: [{ name: "Test Actor", gender: "female" }] } }

      it "returns true" do
        expect(subject.skip?(scene)).to be true
      end
    end

    context "when scene has a keyword in skip_keywords" do
      let(:attr_overrides) { { skip_keywords: ["Test Title"] } }

      it "returns true" do
        expect(subject.skip?(scene)).to be true
      end
    end

    context "when scene's release date is older than oldest_year" do
      let(:attr_overrides) { { oldest_year: 2024 } }

      it "returns true" do
        expect(subject.skip?(scene)).to be true
      end
    end

    context "when scene's duration is shorter than minimum_duration" do
      let(:attr_overrides) { { minimum_duration: "20:00" } }
      let(:overrides) { { duration: "00:30" } }

      it "returns true" do
        expect(subject.skip?(scene)).to be true
      end
    end

    context "when none of the conditions are met" do
      let(:attr_overrides) { {} }

      it "returns false" do
        expect(subject.skip?(scene)).to be false
      end
    end
  end
end
