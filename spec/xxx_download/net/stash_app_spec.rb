# frozen_string_literal: true

require "spec_helper"

RSpec.describe XXXDownload::Net::StashApp, type: :file_support do
  include_context "config provider"
  let(:override_config) { { "stash_app" => { "url" => url } } }
  let(:url) { ENV.fetch("DOCKER_ENV", 0).to_i == 1 ? "host.docker.internal:9999" : "localhost:9999" }

  subject(:stash_app) { described_class.new(config) }

  describe "#setup_credentials!" do
    before do
      VCR.use_cassette("stash_app#setup_credentials") do
        @result = stash_app.setup_credentials!
      end
    end

    it "should return the stash version" do
      expect(@result).to eq("v0.28.1")
    end
  end

  describe "#scene" do
    let(:scene_data) do
      XXXDownload::Data::Scene.new(
        **XXXDownload::Data::Scene::NOT_LAZY,
        title:,
        video_link: "www.test.com",
        network_name: "Test"
      )
    end

    context "when scene exists" do
      let(:title) { "Madisons Swinging Slut" }
      let(:expected_response) do
        { "title" => "",
          "files" => [
            { "path" => "/tmp/Stash/Madisons Swinging Slut [PF] Pornfidelity [A] Kortney Kane, Madison.mp4" }
          ] }
      end

      before do
        VCR.use_cassette("stash_app#scene_exists") do
          @result = stash_app.scene(scene_data)
        end
      end

      it { expect(@result).to eq(expected_response) }
    end

    context "when scene does not exists" do
      let(:title) { "XYZ" }

      before do
        VCR.use_cassette("stash_app#scene_not_exist") do
          @result = stash_app.scene(scene_data)
        end
      end

      it { expect(@result).to be_nil }
    end
  end
end
