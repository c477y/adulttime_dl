# frozen_string_literal: true

require "xxx_download"
require "super_diff/rspec"

Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

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

  config.around(:each, type: :file_support) do |example|
    Dir.mktmpdir("support", Dir.pwd) do |dir|
      Dir.chdir(dir) do
        example.run
      end
    end
  end
end
