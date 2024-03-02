# frozen_string_literal: true

require "rspec"

RSpec.describe XXXDownload::Net::AlgoliaCredentials, type: :file_support do
  context "site requires login" do
    pending "Not Implemented"
    # include_context "config provider"
    #
    # let(:base_uri) { XXXDownload::Constants::BLOW_PASS_BASE_URL }
    # let(:force_login) { true }
    #
    # before do
    #   VCR.use_cassette("algolia_credentials#blowpass") do
    #     @credentials = described_class.new(base_uri, force_login)
    #   end
    # end
    #
    # it "returns the expected credentials" do
    #   expect(@credentials.algolia_application_id).to match(/[A-Z0-9]{10}/)
    #   expect { Base64.strict_decode64(@credentials.algolia_api_key) }.not_to raise_error
    # end
  end

  context "site does not require login" do
    let(:force_login) { false }

    context "site is ztod" do
      let(:base_uri) { XXXDownload::Constants::ZTOD_BASE_URL }

      before do
        VCR.use_cassette("algolia_credentials#ztod") do
          @credentials = described_class.new(base_uri, force_login)
        end
      end

      it "returns the expected credentials" do
        expect(@credentials.algolia_application_id).to match(/[A-Z0-9]{10}/)
        expect { Base64.strict_decode64(@credentials.algolia_api_key) }.not_to raise_error
      end
    end

    context "site is adult_time" do
      let(:base_uri) { XXXDownload::Constants::ADULTTIME_BASE_URL }

      before do
        VCR.use_cassette("algolia_credentials#adulttime") do
          @credentials = described_class.new(base_uri, force_login)
        end
      end

      it "returns the expected credentials" do
        expect(@credentials.algolia_application_id).to match(/[A-Z0-9]{10}/)
        expect(@credentials.algolia_api_key).to match(/[a-z0-9]/)
      end
    end
  end
end
