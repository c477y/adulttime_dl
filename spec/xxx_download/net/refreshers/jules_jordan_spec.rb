# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::Refreshers::JulesJordan, type: :file_support do
  describe "#refresh" do
    subject { described_class.new(path) }

    include_context "config provider"
    let(:placeholder_cookie) { false }

    let(:cookie_str) { ENV.fetch("JULES_JORDAN_COOKIE_STR", "cookie") }
    before do
      # Comment this lines if you have live-credentials to a membership account
      # This will spawn the browser and ask the user for credentials
      allow(subject).to receive(:request_cookie).and_return(cookie_str)
    end

    context "scene with no movie" do
      let(:path) { "/scenes/Bridgette-B-Anal-Milf-Big-Tits_vids.html" }

      before do
        VCR.use_cassette("jules_jordan/refresh/bridgette_b_anal_milf_big_tits_vids") do
          @result = subject.refresh
        end
      end

      let(:expected_attrs) do
        {
          lazy: false,
          video_link: "https://www.julesjordan.com/members/scenes/Bridgette-B-Anal-Milf-Big-Tits_vids.html",
          title: "Manuel The Milfomaniac Enters Bridgette B's Ass",
          actors: [{ name: "Bridgette B", gender: "unknown" },
                   { name: "Manuel Ferrara", gender: "unknown" }],
          network_name: "JulesJordan",
          collection_tag: "JJ",
          release_date: "2024-03-02",
          download_sizes: %w[720P 1080P 4K 480P 360P]
        }
      end

      it "returns the correct attributes" do
        expect(@result.to_h.deep_transform_keys(&:to_sym)).to include(expected_attrs)
      end

      it "returns the correct tags" do
        expected_tags = %w[4k anal asstomouth bigcocks bigtits blondes blowjobs
                           deepthroat facial lingerie milf tattoo]
        expect(@result.tags.to_a).to eq(expected_tags)
      end

      it "returns download links" do
        links = @result.downloading_links

        expect(@result.downloading_links.to_h).to include(:res_1080p, :res_720p, :res_480p, :res_360p, :default)

        expect(%i[res_1080p res_720p res_480p res_360p]
                 .all? { |v| links[v].start_with?("https://api.xvid.com/v1/files/downloads/") })
          .to be_truthy

        expect(links[:default].length).to be > 3
      end
    end

    context "scene with a movie" do
      let(:path) { "/scenes/Manuel-Goes-On-An-Expedition-Into-Kylie-Pages-Amazing-Curves_vids.html" }

      before do
        VCR.use_cassette("jules_jordan/refresh/manuel_goes_on_an_expedition_into_kylie_pages_amazing_curves") do
          @result = subject.refresh
        end
      end

      let(:expected_attrs) do
        {
          lazy: false,
          video_link: "https://www.julesjordan.com/members/scenes/Manuel-Goes-On-An-Expedition-Into-Kylie-Pages-Amazing-Curves_vids.html",
          title: "Manuel Goes On An Expedition Into Kylie Page's Amazing Curves",
          actors: [{ name: "Kylie Page", gender: "unknown" },
                   { name: "Manuel Ferrara", gender: "unknown" }],
          network_name: "Super Stacked #3",
          collection_tag: "JJ",
          release_date: "2023-10-31",
          download_sizes: %w[720P 1080P 4K 480P 360P]
        }
      end

      it "returns the correct attributes" do
        expect(@result.to_h.deep_transform_keys(&:to_sym)).to include(expected_attrs)
      end

      it "returns the correct tags" do
        expected_tags = %w[4k bigbutts bigcocks bigtits blondes blowjobs deepthroat facial lingerie]
        expect(@result.tags.to_a).to eq(expected_tags)
      end

      it "returns download links" do
        links = @result.downloading_links

        expect(@result.downloading_links.to_h).to include(:res_1080p, :res_720p, :res_480p, :res_360p, :default)

        expect(%i[res_1080p res_720p res_480p res_360p]
                 .all? { |v| links[v].start_with?("https://api.xvid.com/v1/files/downloads/") })
          .to be_truthy

        expect(links[:default].length).to be > 3
      end
    end
  end
end
