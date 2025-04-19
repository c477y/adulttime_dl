# frozen_string_literal: true

require "rspec"

class FakeWebDriverProvider
  include XXXDownload::Net::BrowserSupport

  def initialize(base_url, cookie)
    cookie(base_url, cookie)

    # Uncomment during live-test
    # start_browser
  end
end

RSpec.describe XXXDownload::Net::Refreshers::NewSensations, type: :file_support do
  subject { described_class.new(path) }

  include_context "config provider"
  let(:cookie) { "cookie" }
  let(:override_cookie) do
    { "domain" => ".newsensations.com", "cookie" => ENV.fetch("NEW_SENSATIONS_COOKIE_STR", cookie) }
  end

  let(:web_driver) { FakeWebDriverProvider.new("https://newsensations.com", cookie).default_options }

  # Don't set up browser
  before do
    allow_any_instance_of(FakeWebDriverProvider).to receive(:start_browser).and_return("stubbed")
    allow(subject).to receive(:fetch).and_return(nil)
  end

  describe "#refresh" do
    let(:path) { "/gallery.php?id=7716&type=vids&catid=" }

    context "when web-driver is not passed in" do
      it "raises an error" do
        expect { subject.refresh }
          .to raise_error(XXXDownload::FatalError, "#{described_class::TAG} requires the web-driver to refresh scenes")
      end
    end

    context "when web-driver is passed in" do
      let(:scene_data) { subject.refresh(web_driver:) }
      let(:expected_scene_data_attrs) do
        {
          lazy: false,
          video_link: "https://newsensations.com/members/gallery.php?id=7716&type=vids&catid=",
          title: "Savannah Wants To Be Seen In A Post",
          actors: [{ name: "Codey Steele", gender: "unknown" },
                   { name: "Savannah Sixx", gender: "unknown" }],
          network_name: "In The Room",
          collection_tag: "NS",
          release_date: "2020-04-24"
        }
      end

      let(:expected_res_keys) { %i[res_4k res_1080p res_720p default] }

      it "returns the expected scene data", :aggregate_failures do
        pending "Only works with live-credentials"

        expect(scene_data).to be_a(XXXDownload::Data::Scene)
        expect(scene_data.lazy?).to eq(false)
        expect(scene_data.to_h).to include(expected_scene_data_attrs)
        expect(scene_data.downloading_links.to_h.keys).to include(*expected_res_keys)
        expect(scene_data.downloading_links.to_h.select { |k, _| k.to_s.start_with?("res_") }.values)
          .to all(start_with("https://nsnetworkmembers.newsensations.com/members/content/upload"))
      end
    end
  end
end
