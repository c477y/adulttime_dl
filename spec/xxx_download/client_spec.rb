# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Client, type: :file_support do
  include_context "config provider"
  include_context "fake scene provider"

  let(:override_config) do
    {
      urls: {
        performers: ["performer_url"],
        movies: ["movies_url"],
        scenes: ["scene_url"],
        page: ["page_url"]
      },
      parallel: 1
    }
  end

  let(:scenes_index) { instance_double("XXXDownload::Net::BaseIndex") }

  let(:downloader) { instance_double("XXXDownload::Downloader::Download") }
  let(:download_status_store) { instance_double("Data::DownloadStatusDatabase") }

  subject(:instance) { described_class.new }

  before do
    allow(XXXDownload).to receive(:config).and_return(config)
    allow(config).to receive(:scenes_index).and_return(scenes_index)
    allow(instance).to receive(:downloader).and_return(downloader)
    allow(downloader).to receive(:download)

    allow(XXXDownload::Data::DownloadStatusDatabase).to receive(:new).and_return(download_status_store)
    allow(scenes_index).to receive(:search_by_movie).and_return([scene])
    allow(scenes_index).to receive(:search_by_actor).and_return([scene])
    allow(scenes_index).to receive(:search_by_all_scenes).and_return([scene])
    allow(scenes_index).to receive(:search_by_page).and_return([scene])
    allow(scenes_index).to receive(:actor_name).and_return("actor_name")
  end

  describe "#start!" do
    it "processes movies, performers, and scenes" do
      instance.start!

      expect(config).to have_received(:scenes_index)
      expect(scenes_index).to have_received(:search_by_movie).with("movies_url")
      expect(scenes_index).to have_received(:search_by_actor).with("performer_url")
      expect(scenes_index).to have_received(:search_by_all_scenes).with("scene_url")
      expect(scenes_index).to have_received(:search_by_page).with("page_url")

      expect(downloader).to have_received(:download).exactly(4).times
    end

    context "when an actor name cannot be retrieved" do
      before do
        allow(scenes_index).to receive(:actor_name).and_raise(NotImplementedError)
      end

      it "logs a warning and continues processing" do
        instance.start!

        expect(downloader).to have_received(:download).exactly(4).times
      end
    end
  end
end
