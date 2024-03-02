# frozen_string_literal: true

require "xxx_download"
require "simplecov"
require "super_diff/rspec"
require "vcr"
require "webmock/rspec"

SimpleCov.start

Dir["./spec/support/**/*.rb"].each { |f| require f }

IGNORED_URLS = [
  "127.0.0.1",
  "host.docker.internal",
  "localhost",
  "www.adulttime.com",
  "www.evilangel.com",
  "www.zerotolerancefilms.com"
].freeze

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock

  config.before_http_request(:recordable?) do |request|
    msg = "Your spec is trying to make a real HTTP request to \"#{request.uri}\" which VCR will store.\n" \
          "Run your spec inside docker to allow this request to be recorded\n" \
          "e.g. ./bin/docker_rspec spec/xxx_download/net/ztod_index_spec.rb"
    raise msg if ENV.fetch("DOCKER_ENV", 0).to_i != 1
  end

  config.ignore_request do |request|
    uri = URI(request.uri)

    IGNORED_URLS.include?(uri.host) || [9515, 9516].include?(uri.port)
  end

  config.filter_sensitive_data("user") { `echo $HOME`.chomp }
  config.filter_sensitive_data("username") { `whoami`.chomp }
  config.filter_sensitive_data("REDACTED_BY_VCR") do |interaction|
    if interaction.response.headers["Location"]&.any? { |x| x.starts_with?("https://download-fame.gammacdn.com/") }
      interaction.response.headers["Location"] = ["https://download-fame.gammacdn.com/site"]
    end
  end

  config.before_record do |interaction|
    %w[Report-To Nel Server Cf-Ray Cf-Cache-Status
       Cookie Etag Date Set-Cookie
       X-Algolia-Api-Key X-Algolia-Application-Id].each do |h|
      interaction.response.headers.delete(h)
      interaction.request.headers.delete(h)
    end
  end

  # https://benoittgt.github.io/vcr/#/configuration/preserve_exact_body_bytes
  config.preserve_exact_body_bytes do |http_message|
    http_message.body.encoding.name == "ASCII-8BIT" || !http_message.body.valid_encoding?
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Use describe instead of RSpec.describe
  config.expose_dsl_globally = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:all) do
    level = ENV.fetch("LOG_LEVEL", "warn")
    XXXDownload.set_logger(level)
  end

  config.after(:all) do
    FileUtils.rm_f("downloader.log")
  end

  config.around(:each, type: :file_support) do |example|
    Dir.mktmpdir("temp_test_dir_", Dir.pwd) do |dir|
      Dir.chdir(dir) do
        example.run
      end
    end
  end
end
