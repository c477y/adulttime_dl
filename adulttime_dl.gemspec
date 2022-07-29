# frozen_string_literal: true

require_relative "lib/adulttime_dl/version"

Gem::Specification.new do |spec|
  spec.name = "adulttime_dl"
  spec.version = AdultTimeDL::VERSION
  spec.authors = ["c477y"]
  spec.email = ["c477y@pm.me"]

  spec.summary = "Gem to downloader videos from adulttime.com"
  spec.description = spec.summary
  spec.homepage = "https://www.github.com/c477y/adulttime_dl"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "pry", "~> 0.14.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rbs", "~> 2.5"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "typeprof", "~> 0.21.2"

  spec.add_runtime_dependency "algolia"
  spec.add_runtime_dependency "colorize", "~> 0.8.1"
  spec.add_runtime_dependency "dry-schema", "~> 1.9"
  spec.add_runtime_dependency "dry-struct", "~> 1.4"
  spec.add_runtime_dependency "dry-types", "~> 1.5"
  spec.add_runtime_dependency "dry-validation", "~> 1.8"
  spec.add_runtime_dependency "httparty", "~> 0.20.0"
  spec.add_runtime_dependency "http-cookie", "~> 1.0"
  spec.add_runtime_dependency "nokogiri", "~> 1.13"
  spec.add_runtime_dependency "parallel", "~> 1.22"
  spec.add_runtime_dependency "selenium-devtools", "~> 0.103.1"
  spec.add_runtime_dependency "selenium-webdriver", "~> 4.3"
  spec.add_runtime_dependency "thor", "~> 1.2"
  spec.add_runtime_dependency "webdrivers", "~> 5.0"
end
