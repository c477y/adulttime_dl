# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::Refreshers::Spizoo do
  let(:cookie_str) { ENV.fetch("SPIZOO_COOKIE_STR", "cookie") }

  subject { described_class.new(path, cookie_str) }

  describe "#refresh" do
    context "scene 1: Kenzie Taylor's Ex Boyfriend" do
      let(:path) { "/gallery.php?id=2449&type=vids" }

      before do
        # reuse the same cassette because the site is the same
        VCR.use_cassette("spizoo/index_search_by_all_scenes#kenzie_taylors_ex_boyfriend") do
          @result = subject.refresh
        end
      end

      let(:expected_attrs) do
        { lazy: false,
          video_link: "https://www.spizoo.com/members/gallery.php?id=2449&type=vids",
          title: "Kenzie Taylor's Ex Boyfriend 4k",
          actors: [{ name: "Kenzie Taylor", gender: "unknown" }],
          network_name: "Sinful Taboo Confessions",
          collection_tag: "SPZ",
          release_date: "2019-01-16",
          download_sizes: %w[4K 1080P 720P 480P 480P 272P 320P] }
      end

      it "returns the correct attributes" do
        expect(@result.to_h.deep_transform_keys(&:to_sym)).to include(expected_attrs)
      end

      it "returns the correct tags" do
        expected_tags = %w[4k bigdicks bigtits blonde blowjob busty cowgirl cumshot deepthroat dirtytalk doggystyle
                           getcaught hardcore lingerie missionary pornstar realityporn tattoo throated]
        expect(@result.tags.to_a).to eq(expected_tags)
      end

      it "returns download links" do
        links = @result.downloading_links

        expect(@result.downloading_links.to_h).to include(:res_4k, :res_1080p, :res_720p, :res_480p, :default)

        expect(%i[res_4k res_1080p res_720p res_480p]
                 .all? { |v| links[v].start_with?("https://content.spizoo.com/members/content/upload") })
          .to be_truthy

        expect(links[:default].length).to be > 4
      end
    end

    context "scene 2: Jennifer Mendez Loves To Squirt On A Big Dick" do
      let(:path) { "/gallery.php?id=5921&type=vids" }

      before do
        # reuse the same cassette because the site is the same
        VCR.use_cassette("spizoo/refresh#jennifer_mendez_loves_to_squirt_on_a_big_dick") do
          @result = subject.refresh
        end
      end

      let(:expected_attrs) do
        { lazy: false,
          video_link: "https://www.spizoo.com/members/gallery.php?id=5921&type=vids",
          title: "Jennifer Mendez Loves To Squirt On A Big Dick",
          actors: [{ name: "Jennifer Mendez", gender: "unknown" }],
          network_name: "Spizoo",
          collection_tag: "SPZ",
          release_date: "2024-02-28",
          download_sizes: %w[4K 1080P 720P 480P 320P] }
      end

      it "returns the correct attributes" do
        expect(@result.to_h.deep_transform_keys(&:to_sym)).to include(expected_attrs)
      end

      it "returns the correct tags" do
        expected_tags = %w[4k bigass bigtits blowjob boygirl brunette cowgirl cuminmouth cumonface cumshot curvy facial
                           hairypussy handjob latex missionary pussylicking reversecowgirl spooning squirting tattooed]
        expect(@result.tags.to_a).to eq(expected_tags)
      end

      it "returns download links" do
        links = @result.downloading_links

        expect(@result.downloading_links.to_h).to include(:res_4k, :res_1080p, :res_720p, :res_480p, :default)

        expect(%i[res_4k res_1080p res_720p res_480p]
                 .all? { |v| links[v].start_with?("https://content.spizoo.com/members/content/upload") })
          .to be_truthy

        expect(links[:default].length).to be > 4
      end
    end
  end
end
