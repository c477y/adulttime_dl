# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::ResolutionHelper do
  let(:dummy_class) { Class.new { include XXXDownload::ResolutionHelper } }
  let(:instance) { dummy_class.new }
  let(:config_class) { Struct.new(:quality) }

  before { instance.instance_variable_set(:@config, config_class.new(quality)) }

  describe "#matched_url" do
    subject { instance.matched_url(res_hash) }

    let(:res_hash) do
      {
        "4K" => "https://example.com/4k_video",
        "1080p" => "https://example.com/1080p_video",
        "720p" => "https://example.com/720p_video",
        "360p" => "https://example.com/360p_video"
      }
    end

    context "when quality is fhd" do
      let(:quality) { "fhd" }

      it "returns the URL matching 1080p resolution" do
        expect(subject).to eq("https://example.com/1080p_video")
      end
    end

    context "when quality is hd" do
      let(:quality) { "hd" }

      it "returns the URL matching 720p resolution" do
        expect(subject).to eq("https://example.com/720p_video")
      end
    end

    context "when quality is sd" do
      let(:quality) { "sd" }

      it "returns the URL matching 360p resolution" do
        expect(subject).to eq("https://example.com/360p_video")
      end
    end

    context "when quality does not match any resolution" do
      let(:quality) { "nonexistent" }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when the hash is empty" do
      let(:quality) { "sd" }
      let(:res_hash) { {} }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end
end
