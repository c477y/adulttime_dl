# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::Generators::ZtodGenerator do
  subject { described_class.new(config) }

  let(:config) { XXXDownload::Data::GeneratorConfig.new({ site: "ztod", object: }) }

  before do
    VCR.configure do |c|
      c.ignore_hosts("www.zerotolerancefilms.com", "members.zerotolerancefilms.com")
    end
  end

  describe "#actors" do
    let(:object) { "actors" }

    before do
      VCR.use_cassette("ztod_generator#actors") do
        @result = subject.actors
      end
    end

    it "returns a list of actors" do
      @result.each do |url|
        expect { URI.parse(url) }.not_to raise_error
      end
    end
  end

  describe "#movies" do
    let(:object) { "movies" }

    before do
      VCR.use_cassette("ztod_generator#movies") do
        @result = subject.movies
      end
    end

    it "returns a list of movies" do
      @result.each do |url|
        expect { URI.parse(url) }.not_to raise_error
      end
    end
  end
end
