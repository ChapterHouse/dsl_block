# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dsl_block/version'

Gem::Specification.new do |spec|
  spec.name          = 'dsl_block'
  spec.version       = DslBlock::VERSION
  spec.authors       = ['Frank Hall']
  spec.email         = ['ChapterHouse.Dune@gmail.com']
  spec.summary       = %q{Quick and simple DSL creator.}
  spec.description   = %q{DslBlock is a quick and simple DSL creator.}
  spec.homepage      = 'http://chapterhouse.github.io/dsl_block'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 4.0'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 2.14.1'
  spec.add_development_dependency 'simplecov', '~> 0.7.1'
  spec.add_development_dependency 'rdoc', '~> 4.0.0'

end
