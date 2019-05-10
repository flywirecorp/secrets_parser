lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'secrets_parser/version'

Gem::Specification.new do |spec|
  spec.name          = 'secrets_parser'
  spec.version       = SecretsParser::VERSION
  spec.license       = 'MIT'
  spec.authors       = ['Paco Sanchez']
  spec.email         = ['sanchezpaco@users.noreply.github.com']

  spec.summary       = %q{Write a short summary, because RubyGems requires one.}
  spec.description   = %q{Write a longer description or delete this line.}
  spec.homepage      = 'https://github.com/peertransfer/secrets_parser'

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://travis-ci.org/'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  files = Dir['lib/**/*.rb', 'bin/*']
  rootfiles = ['Gemfile', 'secrets_parser.gemspec', 'README.md', 'Rakefile', 'CODE_OF_CONDUCT.md']
  dotfiles = []
  spec.files = files + rootfiles + dotfiles

  spec.bindir = 'bin'
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
