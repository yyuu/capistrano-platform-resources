# -*- encoding: utf-8 -*-
require File.expand_path('../lib/capistrano/configuration/resources/platform_resources/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Yamashita Yuu"]
  gem.email         = ["yamashita@geishatokyo.com"]
  gem.description   = %q{A sort of utilities which helps you to manage platform resources.}
  gem.summary       = %q{A sort of utilities which helps you to manage platform resources.}
  gem.homepage      = "https://github.com/yyuu/capistrano-platform-resources"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "capistrano-platform-resources"
  gem.require_paths = ["lib"]
  gem.version       = Capistrano::Configuration::Resources::PlatformResources::VERSION

  gem.add_dependency("capistrano")
  gem.add_development_dependency("vagrant", "~> 1.0.6")
end
