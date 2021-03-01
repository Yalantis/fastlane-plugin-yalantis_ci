# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/yalantis_ci/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-yalantis_ci'
  spec.version       = Fastlane::YalantisCi::VERSION
  spec.author        = 'Dima Vorona'
  spec.email         = 'dmytro.vorona@yalantis.net'

  spec.summary       = 'Set of utilities and useful actions to help setup CI for Yalantis projects'
  # spec.homepage      = "https://github.com/<GITHUB_USERNAME>/fastlane-plugin-yalantis_ci"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'fastlane-plugin-firebase_app_distribution', '~> 0.1'

  spec.add_development_dependency('pry')
  spec.add_development_dependency('bundler')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('rspec_junit_formatter')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rubocop', '0.49.1')
  spec.add_development_dependency('rubocop-require_tools')
  spec.add_development_dependency('simplecov')
  spec.add_development_dependency('fastlane', '>= 2.175.0')
end
