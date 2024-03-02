# frozen_string_literal: true

require "rspec"
require "xxx_download/data/config"

shared_context "config provider" do
  # Input: Pass some keys in this hash to override default keys
  let(:override_config) { {} }
  let(:override_opts) { {} }
  let(:site) { "goodporn" }
  let(:placeholder_cookie) { true }

  # Output: Access config
  let(:config) { XXXDownload::Contract::ConfigGenerator.new(site, override_opts).generate }

  ## Create a config file beforehand so that ConfigGenerator doesn't throw an error
  before(:each) do |example|
    unless example.metadata[:type] == :file_support
      raise "shared context 'config provider' should only be used with specs that have type: :file_support"
    end

    default_config = XXXDownload::Contract::Default.cleaned_config

    # Override the cdp_host to point to the host's remote driver
    # to allow tests to open browsers. You will need to run the chromedriver
    # on your host machine to make this work.
    default_config["cdp_host"] = "http://host.docker.internal:9515" if ENV.fetch("DOCKER_ENV", 0).to_i == 1

    config = override_config.deeper_merge(default_config)
    config.deep_transform_keys!(&:to_s)
    config.merge!("site" => site)
    File.write("config.yml", config.to_yaml)

    # write placeholder data in a cookie file
    if placeholder_cookie
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
