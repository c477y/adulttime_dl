# frozen_string_literal: true

require "xxx_download"
require "simplecov"
require "super_diff/rspec"
require "vcr"
require "webmock/rspec"

SimpleCov.start

Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data("user") { `echo $HOME`.chomp }
  config.filter_sensitive_data("username") { `whoami`.chomp }
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
    level = ENV.fetch("LOG_LEVEL", "fatal")
    XXXDownload.set_logger(level)
  end

  config.after(:all) do
    FileUtils.rm("downloader.log") if File.exist?("downloader.log")
  end

  config.around(:each, type: :file_support) do |example|
    Dir.mktmpdir("temp_test_dir_", Dir.pwd) do |dir|
      Dir.chdir(dir) do
        example.run
      end
    end
  end
end
