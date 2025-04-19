# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Downloader::Download, type: :file_support do
  let(:downloader) { described_class.new(store:, semaphore:) }

  include_context "config provider"
  include_context "fake scene provider"

  let(:semaphore) { Mutex.new }
  let(:store) { XXXDownload::Data::DownloadStatusDatabase.new(config.store, semaphore) }
  let(:scene_index) { instance_double("XXXDownload::Net::BaseIndex") }

  describe "#download" do
    context "file already downloaded" do
      context "when scene data is present in the store" do
        before { store.save_download(scene) }

        it "does not download the file again" do
          expect(downloader.download(scene, scene_index)).to eq(false)
        end
      end

      context "when file exists in the current directory" do
        before { FileUtils.touch("#{scene.file_name}.mp4") }

        it "does not download the file again" do
          expect(downloader.download(scene, scene_index)).to eq(false)
        end
      end
    end

    context "when the file has not been downloaded yet" do
      context "when the download link is available" do
        let(:override_scene_params) do
          {
            downloading_links: {
              res_720p: "https://example.com"
            }
          }
        end

        before do
          allow(downloader).to receive(:start_download).with(scene, anything).and_return(true)
          allow(scene_index).to receive(:command).and_return("")
        end

        it "downloads the file using the download link" do
          downloader.download(scene, scene_index)
          expect(downloader).to have_received(:start_download).with(scene, anything)
        end
      end

      context "when the download link is not available" do
        before do
          allow(downloader).to receive(:download_link_fetcher).and_return(double(fetch: nil))
        end

        let(:streaming_link) { XXXDownload::Data::StreamingLinks.with_single_url("https://example.com") }

        context "when the streaming link is available" do
          before do
            allow(downloader).to receive(:streaming_link_fetcher).and_return(double(fetch: streaming_link))
            allow(scene_index).to receive(:command).and_return("")
          end

          it "downloads the file using the streaming link" do
            expect(downloader).to receive(:start_download)
              .with(an_instance_of(XXXDownload::Data::Scene), anything)
              .and_return(true)
            downloader.download(scene, scene_index)
          end
        end

        context "when the streaming link is not available" do
          before do
            allow(downloader).to receive(:streaming_link_fetcher).and_return(double(fetch: nil))
          end

          it "does not download the file" do
            expect(downloader.download(scene, scene_index)).to eq(false)
          end
        end
      end
    end
  end
end
