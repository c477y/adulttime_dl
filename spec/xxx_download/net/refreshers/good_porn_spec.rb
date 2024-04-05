# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::Refreshers::GoodPorn do
  describe "#refresh" do
    subject { described_class.new(path) }
    let(:path) { "/videos/59217/brazzers-exxtra-the-sauna-is-heating-up-02-27-2024/" }

    before do
      VCR.use_cassette("goodporn-success#sauna-is-heating-up") do
        @result = subject.refresh
      end
    end
    let(:expected_attrs) do
      {
        lazy: false,
        video_link: "https://goodporn.to/videos/59217/brazzers-exxtra-the-sauna-is-heating-up-02-27-2024/",
        title: "The Sauna Is Heating Up",
        actors: [{ name: "Coco Rains", gender: "unknown" },
                 { name: "Xander Corvus", gender: "unknown" }],
        network_name: "Brazzers Exxtra",
        collection_tag: "BZ",
        release_date: "2024-02-27",
        download_sizes: %w[360p 480p 720p 1080p 2160p]
      }
    end

    it "returns the correct attributes" do
      expect(@result.to_h.deep_transform_keys(&:to_sym)).to include(expected_attrs)
    end

    it "returns the correct tags" do
      expected_tags =
        %w[xandercorvus cocorains piercing muscularman americanman shorthair bigdick bigass curvywoman
           brunette shaved bigtits cumshot facial kissing sneaky oil blowjob deepthroat facefuck gagging hairpulling
           spanking tittyfuck assworship cowgirl doggystyle missionary topad 4kvideos brazzersexxtra 2024]
      expect(@result.tags.to_a).to eq(expected_tags)
    end

    it "returns download links" do
      links = @result.downloading_links

      expect(@result.downloading_links.to_h).to include(:res_1080p, :res_720p, :res_480p, :default)

      expect(%i[res_1080p res_720p res_480p]
               .all? { |v| links[v].start_with?("https://goodporn.to/get_file/") })
        .to be_truthy

      expect(links[:default].length).to be > 3
    end
  end
end
