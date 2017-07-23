# -*- encoding: utf-8 -*-

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'pronto/inspec/version'

Gem::Specification.new do |s|
  s.name = 'pronto-inspec'
  s.version = Pronto::InspecVersion::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['stiller-leser']
  s.email = ''
  s.homepage = 'https://github.com/stiller-leser/pronto-inspec'
  s.summary = <<-EOF
    Pronto runner for running test kitchen
  EOF

  s.licenses = ['MIT']
  s.required_ruby_version = '>= 2.0.0'
  s.rubygems_version = '1.8.23'

  s.files = Dir.glob('{lib}/**/*') + %w[LICENSE README.md]
  s.test_files = `git ls-files -- {spec}/*`.split("\n")
  s.extra_rdoc_files = ['LICENSE', 'README.md']
  s.require_paths = ['lib']

  s.add_dependency('pronto', '~> 0.9.0')
  s.add_dependency('rugged', '~> 0.24', '>= 0.23.0')
  s.add_dependency('colorize', '~> 0.8')
  s.add_dependency('nokogiri', '~> 1.8')
  s.add_development_dependency('rake', '~> 12.0')
  s.add_development_dependency('rspec', '~> 3.4')
  s.add_development_dependency('byebug', '~> 0')
end
