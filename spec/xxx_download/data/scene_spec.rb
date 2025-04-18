# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Data::Scene do
  subject { described_class.new(attributes) }

  context "when a scene is lazy evaluated" do
    context "when correct attributes are provided" do
      let(:attributes) do
        {
          refresher: XXXDownload::Net::Refreshers::BaseRefresh.new,
          video_link: "https://example.com",
          **described_class::LAZY
        }
      end

      it "returns true" do
        expect(subject.lazy?).to be true
      end
    end

    context "when refresher is not provided" do
      let(:attributes) do
        {
          video_link: "https://example.com",
          **described_class::LAZY
        }
      end

      it "raises a FatalError" do
        expect { subject }.to raise_error(XXXDownload::FatalError, "Lazy evaluated scenes must have a refresher")
      end
    end
  end

  describe "file_name" do
    context "when release_date is present" do
      let(:attributes) do
        {
          lazy: false,
          video_link: "https://example.com",
          release_date: "2022-01-01",
          title: "Test Title",
          collection_tag: "Test Tag",
          network_name: "Test Network",
          actors: []
        }
      end

      it "includes release_date in the file name" do
        expect(subject.file_name).to include("2022-01-01")
      end
    end

    context "when movie_title is present" do
      let(:attributes) do
        {
          lazy: false,
          video_link: "https://example.com",
          movie_title: "Test Movie",
          title: "Test Title",
          collection_tag: "Test Tag",
          network_name: "Test Network",
          actors: []
        }
      end

      it "includes movie_title in the file name" do
        expect(subject.file_name).to include("Test Movie")
      end
    end

    context "when gender of all actors is unknown" do
      let(:attributes) do
        {
          lazy: false,
          video_link: "https://example.com",
          title: "Test Title",
          collection_tag: "Test Tag",
          network_name: "Test Network",
          actors: [{ name: "Test Actor", gender: "unknown" }]
        }
      end

      it "includes [A] in the file name" do
        expect(subject.file_name).to include("[A]")
      end
    end

    context "when there are female and male actors" do
      let(:attributes) do
        {
          lazy: false,
          video_link: "https://example.com",
          title: "Test Title",
          collection_tag: "Test Tag",
          network_name: "Test Network",
          actors: [{ name: "Test Actor", gender: "female" }, { name: "Test Actor 2", gender: "male" }]
        }
      end

      it "includes [F] and [M] in the file name" do
        expect(subject.file_name).to include("[F]")
        expect(subject.file_name).to include("[M]")
      end
    end

    context "when the file name exceeds the maximum length" do
      let(:attributes) do
        {
          lazy: false,
          video_link: "https://example.com",
          title: "Test Title",
          collection_tag: "Test Tag",
          network_name: "Test Network",
          actors: Array.new(50) { { name: "Test Actor", gender: "female" } }
        }
      end

      it "truncates the file name" do
        expect(subject.file_name.length).to be < XXXDownload::Data::Scene::MAX_FILENAME_LEN
      end
    end
  end

  describe "lesbian?" do
    context "when all actors are female" do
      let(:attributes) do
        {
          lazy: false,
          video_link: "https://example.com",
          title: "Test Title",
          collection_tag: "Test Tag",
          network_name: "Test Network",
          actors: [{ name: "Test Actor", gender: "female" }, { name: "Test Actor 2", gender: "female" }]
        }
      end

      it "returns true" do
        expect(subject.lesbian?).to be true
      end
    end

    context "when there are male actors" do
      let(:attributes) do
        {
          lazy: false,
          video_link: "https://example.com",
          title: "Test Title",
          collection_tag: "Test Tag",
          network_name: "Test Network",
          actors: [{ name: "Test Actor", gender: "female" }, { name: "Test Actor 2", gender: "male" }]
        }
      end

      it "returns false" do
        expect(subject.lesbian?).to be false
      end
    end

    context "when gender of all actors is unknown" do
      let(:attributes) do
        {
          lazy: false,
          video_link: "https://example.com",
          title: "Test Title",
          collection_tag: "Test Tag",
          network_name: "Test Network",
          actors: [{ name: "Test Actor", gender: "unknown" }]
        }
      end

      it "returns false" do
        expect(subject.lesbian?).to be false
      end
    end
  end

  describe "#available_resolution" do
    context "when quality is 'sd'" do
      let(:attributes) do
        {
          lazy: false,
          video_link: "https://example.com",
          title: "Test Title",
          collection_tag: "Test Tag",
          network_name: "Test Network",
          actors: [],
          download_sizes: %w[480p 720p 1080p]
        }
      end

      it "returns '480p'" do
        expect(subject.available_resolution("sd")).to eq("480p")
      end
    end

    context "when quality is 'hd' and '720p' is not available" do
      let(:attributes) do
        {
          lazy: false,
          video_link: "https://example.com",
          title: "Test Title",
          collection_tag: "Test Tag",
          network_name: "Test Network",
          actors: [],
          download_sizes: %w[480p 576p 1080p]
        }
      end

      it "returns '576p'" do
        expect(subject.available_resolution("hd")).to eq("576p")
      end
    end

    context "when quality is 'fhd' and '1080p' is not available" do
      let(:attributes) do
        {
          lazy: false,
          video_link: "https://example.com",
          title: "Test Title",
          collection_tag: "Test Tag",
          network_name: "Test Network",
          actors: [],
          download_sizes: %w[480p 720p]
        }
      end

      it "returns the last available resolution" do
        expect(subject.available_resolution("fhd")).to eq("720p")
      end
    end

    context "when no download_sizes are available" do
      let(:attributes) do
        {
          lazy: false,
          video_link: "https://example.com",
          title: "Test Title",
          collection_tag: "Test Tag",
          network_name: "Test Network",
          actors: [],
          download_sizes: []
        }
      end

      it "returns an empty string" do
        expect(subject.available_resolution("fhd")).to eq("")
      end
    end
  end

  describe "#refresh" do
    context "when refresher is present" do
      let(:refresher) do
        class TestRefresher < XXXDownload::Net::Refreshers::BaseRefresh # rubocop:disable Lint/ConstantDefinitionInBlock
          def refresh
            XXXDownload::Data::Scene.new(
              lazy: false,
              video_link: "https://example.com",
              title: "Refreshed Title",
              collection_tag: "Test Tag",
              network_name: "Test Network",
              actors: []
            )
          end
        end

        TestRefresher.new
      end

      let(:attributes) do
        {
          lazy: true,
          video_link: "https://example.com",
          refresher:,
          **described_class::LAZY
        }
      end

      it "returns a scene with refreshed data" do
        refreshed_scene = subject.refresh
        expect(refreshed_scene.title).to eq("Refreshed Title")
      end
    end

    context "when refresher is not present" do
      let(:attributes) do
        {
          lazy: false,
          video_link: "https://example.com",
          title: "Test Title",
          collection_tag: "Test Tag",
          network_name: "Test Network",
          actors: []
        }
      end

      it "returns the same scene" do
        expect(subject.refresh).to eq(subject)
      end
    end
  end
end
