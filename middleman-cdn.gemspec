# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'middleman-cdn/version'

Gem::Specification.new do |s|
  s.name        = 'middleman-cdn'
  s.version     = Middleman::CDN::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Leigh McCulloch"]
  s.homepage    = "https://github.com/leighmcculloch/middleman-cdn"
  s.summary     = %q{Invalidate CloudFlare or CloudFront cache after deployment}
  s.description = %q{Invalidate a specific set of files in your CloudFlare or CloudFront cache}

  s.files         = `git ls-files -z`.split("\0")
  s.test_files    = `git ls-files -z -- {fixtures,features}/*`.split("\0")
  s.require_paths = ["lib"]

  s.add_dependency 'fog', '~> 1.9'
  s.add_dependency 'cloudflare', '~> 2.0'
  s.add_dependency 'colorize'

  s.add_development_dependency 'cucumber', '~> 1.3'
  s.add_development_dependency 'aruba', '~> 0.5'
  s.add_development_dependency 'fivemat', '~> 1.3'
  s.add_development_dependency 'simplecov', '~> 0.8'
  s.add_development_dependency 'rake', '~> 0.9'

  s.add_development_dependency 'rspec', '~> 3.0'

  if RUBY_VERSION <= '1.9.2'
    s.add_dependency 'middleman-core', '~> 3.0', '<= 3.2.0'
    s.add_development_dependency 'activesupport', '< 4.0.0'
  else
    s.add_dependency 'middleman-core', '~> 3.0'
    s.add_development_dependency 'activesupport', '~> 4.1'
  end
end
