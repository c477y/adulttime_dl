# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Data::StreamingLinks do
  subject { described_class.new(attributes) }

  describe "#sd" do
    context "when res_480p is available" do
      let(:attributes) { { res_480p: "480p_url" } }

      it "returns res_480p url" do
        expect(subject.sd).to eq("480p_url")
      end
    end

    context "when res_480p is not available but res_432p is available" do
      let(:attributes) { { res_432p: "432p_url" } }

      it "returns res_432p url" do
        expect(subject.sd).to eq("432p_url")
      end
    end

    context "when neither res_480p nor res_432p is available but default is available" do
      let(:attributes) { { default: ["default_url"] } }

      it "returns the first default url" do
        expect(subject.sd).to eq("default_url")
      end
    end

    context "when no url is available" do
      let(:attributes) { {} }

      it "returns nil" do
        expect(subject.sd).to be_nil
      end
    end
  end

  describe "#hd" do
    context "when res_720p is available" do
      let(:attributes) { { res_720p: "720p_url" } }

      it "returns res_720p url" do
        expect(subject.hd).to eq("720p_url")
      end
    end

    context "when res_720p is not available but res_576p is available" do
      let(:attributes) { { res_576p: "576p_url" } }

      it "returns res_576p url" do
        expect(subject.hd).to eq("576p_url")
      end
    end

    context "when neither res_720p nor res_576p is available but sd is available" do
      let(:attributes) { { res_480p: "480p_url" } }

      it "returns the sd url" do
        expect(subject.hd).to eq("480p_url")
      end
    end
  end

  describe "#fhd" do
    context "when res_1080p is available" do
      let(:attributes) { { res_1080p: "1080p_url" } }

      it "returns res_1080p url" do
        expect(subject.fhd).to eq("1080p_url")
      end
    end

    context "when res_1080p is not available but hd is available" do
      let(:attributes) { { res_720p: "720p_url" } }

      it "returns the hd url" do
        expect(subject.fhd).to eq("720p_url")
      end
    end
  end

  describe ".with_single_url" do
    let(:url) { "single_url" }

    it "returns a new instance with default set to an array containing the provided url" do
      streaming_links = described_class.with_single_url(url)
      expect(streaming_links.default).to eq([url])
    end
  end
end
