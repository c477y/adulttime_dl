# frozen_string_literal: true

require "rspec"
require "xxx_download/data/config"

shared_context "config provider" do
  # Input: Pass some keys in this hash to override default keys
  let(:override_config) { {} }
  let(:override_opts) { {} }
  let(:site) { "goodporn" }

  # Output: Access config
  let(:config) { XXXDownload::Contract::ConfigGenerator.new(site, override_opts).generate }

  ## Create a config file beforehand so that ConfigGenerator doesn't throw an error
  before(:each) do |example|
    unless example.metadata[:type] == :file_support
      raise "shared context 'config provider' should only be used with specs that have type: :file_support"
    end

    default_config = XXXDownload::Contract::Default.cleaned_config
    config = override_config.deeper_merge(default_config)
    config.deep_transform_keys!(&:to_s)
    config.merge!("site" => site)
    File.open("config.yml", "w") { |f| f.write(config.to_yaml) }

    XXXDownload.set_config(XXXDownload::Data::Config.new(config))
  end
end
