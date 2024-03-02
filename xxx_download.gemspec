# frozen_string_literal: true

require_relative "lib/xxx_download/version"

Gem::Specification.new do |spec|
  spec.name = "xxx_download"
  spec.version = XXXDownload::VERSION
  spec.authors = ["c477y"]
  spec.email = ["c477y@pm.me"]

  spec.summary = "Gem to downloader videos from adulttime.com"
  spec.description = spec.summary
  spec.homepage = "https://www.github.com/c477y/adulttime_dl"
  spec.required_ruby_version = ">= 3.1.2"

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

  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "algolia"
  spec.add_runtime_dependency "awesome_print", "~> 1.9"
  spec.add_runtime_dependency "colorize", "~> 0.8"
  spec.add_runtime_dependency "deep_merge", "~> 1.2"
  spec.add_runtime_dependency "dry-schema", "~> 1.9"
  spec.add_runtime_dependency "dry-struct", "~> 1.4"
  spec.add_runtime_dependency "dry-types", "~> 1.5"
  spec.add_runtime_dependency "dry-validation", "~> 1.8"
  spec.add_runtime_dependency "httparty", "~> 0.20"
  spec.add_runtime_dependency "http-cookie", "~> 1.0"
  spec.add_runtime_dependency "nokogiri", "~> 1.13"
  spec.add_runtime_dependency "parallel", "~> 1.22"
  spec.add_runtime_dependency "progressbar", "~> 1.13"
  spec.add_runtime_dependency "thor", "~> 1.2"
  spec.add_runtime_dependency "zeitwerk", "~> 2.6"

  spec.add_runtime_dependency "selenium-devtools", "= 0.123.0"
  spec.add_runtime_dependency "selenium-webdriver", "= 4.19.0"
  spec.metadata["rubygems_mfa_required"] = "true"
end
