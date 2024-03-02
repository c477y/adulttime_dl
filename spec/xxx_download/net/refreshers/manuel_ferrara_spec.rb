# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::Refreshers::ManuelFerrara, type: :file_support do
  describe "#refresh" do
    subject { described_class.new(path) }

    include_context "config provider"
    let(:placeholder_cookie) { false }

    let(:cookie_str) { ENV.fetch("MANUEL_FERRARA_COOKIE_STR", "cookie") }
    before do
      # Comment this lines if you have live-credentials to a membership account
      # This will spawn the browser and ask the user for credentials
      allow(subject).to receive(:request_cookie).and_return(cookie_str)
    end

    context "Super Stacked #2" do
      let(:path) { "/scenes/Arabelle-Raphael-Anal_vids.html" }

      before do
        VCR.use_cassette("manuel_ferrara/refresh/arabelle_raphael_anal") do
          @result = subject.refresh
        end
      end

      let(:expected_attrs) do
        { lazy: false,
          video_link: "https://www.manuelferrara.com/members/scenes/Arabelle-Raphael-Anal_vids.html",
          title: "Anal Slut Arabelle Raphael Shows Off Her Massive Mammaries",
          actors: [{ name: "Arabelle Raphael", gender: "unknown" },
                   { name: "Manuel Ferrara", gender: "unknown" }],
          network_name: "Super Stacked #2",
          collection_tag: "MNF",
          release_date: "2022-09-21" }
      end

      it "returns the correct attributes" do
        expect(@result.to_h.deep_transform_keys(&:to_sym)).to include(expected_attrs)
      end

      it "returns the correct tags" do
        expected_tags = %w[4k anal asstomouth bigbutts bigcocks bigtits blowjobs brunettes deepthroat
                           facial lingerie rimming tattoo]
        expect(@result.tags.to_a).to eq(expected_tags)
      end

      it "returns download links" do
        links = @result.downloading_links

        expect(@result.downloading_links.to_h).to include(:res_1080p, :res_720p, :res_360p, :default)

        expect(%i[res_1080p res_720p res_360p]
                 .all? { |v| links[v].start_with?("https://api.xvid.com/v1/files/downloads/") })
          .to be_truthy

        expect(links[:default].length).to eq(4)
      end
    end
  end
end
