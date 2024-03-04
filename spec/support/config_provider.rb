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

    # write placeholder data in a cookie file
    if config["cookie_file"].present?
      File.open(config["cookie_file"], "w") do |file|
        cookie_data = <<~COOKIE
          # Netscape HTTP Cookie File
          # https://curl.haxx.se/rfc/cookie_spec.html
          # This is a generated file!  Do not edit.

          #HttpOnly_example.com	TRUE	/	FALSE	9999999999	cookie_name	cookie_value
        COOKIE
        file.write(cookie_data)
      end
    end

    # set the config in the application namespace
    XXXDownload.set_config(XXXDownload::Data::Config.new(config))
  end
end

shared_context "fake scene provider" do
  let(:override_scene_params) { {} }

  let(:scene) do
    XXXDownload::Data::Scene.new(
      {
        lazy: false,
        video_link: "https://example.com",
        clip_id: 1,
        title: "Fake Scene",
        actors: [
          { name: "Actor 1", gender: "female" },
          { name: "Actor 2", gender: "male" }
        ],
        network_name: "Fake Network",
        collection_tag: "N",
        release_date: "2020-01-01",
        movie_title: "Fake Movie"
      }.merge(override_scene_params)
    )
  end
end
