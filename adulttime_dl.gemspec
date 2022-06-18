# frozen_string_literal: true

require_relative "lib/adulttime_dl/version"

Gem::Specification.new do |spec|
  spec.name = "adulttime-dl"
  spec.version = AdulttimeDl::VERSION
  spec.authors = ["c477y"]
  spec.email = ["c477y@pm.me"]

  spec.summary = "Gem to download videos from adulttime.com"
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
end
