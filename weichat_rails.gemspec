# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'weichat_rails/version'

Gem::Specification.new do |spec|
  spec.name          = "weichat_rails"
  spec.version       = WeichatRails::VERSION
  spec.authors       = ["javy_liu"]
  spec.email         = ["javy_liu@163.com"]
  spec.summary       = %q{wechat interface for rails based on weichat-rails}
  spec.description   = %q{used for more than one public wechat account,base on the mysql,~> rails 3.2.16}
  spec.homepage      = "https://github.com/javyliu/weichat_rails"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"

  spec.add_dependency "rails"#, "~> 3.2.14"
  spec.add_dependency "nokogiri", '>=1.6.0'
  spec.add_dependency 'rest-client'
  spec.add_dependency 'dalli'

end
