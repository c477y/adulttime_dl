# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Data::DownloadStatusDatabase, type: :file_support do
  subject { described_class.new("adt.pstore", semaphore) }

  let(:semaphore) { Mutex.new }
  let(:scene) do
    XXXDownload::Data::Scene.new(
      lazy: false,
      video_link: "https://example.com",
      release_date: "2022-01-01",
      title: "Test Title",
      collection_tag: "Test Tag",
      network_name: "Test Network",
      actors: []
    )
  end

  describe "#downloaded?" do
    context "when scene data is present in the store" do
      before do
        subject.save_download(scene)
      end

      it "returns true" do
        expect(subject.downloaded?(scene.key)).to be true
      end
    end

    context "when scene data is not present in the store" do
      it "returns false" do
        expect(subject.downloaded?("non_existent_key")).to be false
      end
    end
  end

  describe "#save_download" do
    it "saves the scene data to the store" do
      expect { subject.save_download(scene) }
        .to change { subject.downloaded?(scene.key) }.from(false).to(true)
    end
  end
end
