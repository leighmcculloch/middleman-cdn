lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'middleman-cdn/version'

Gem::Specification.new do |s|
  s.name        = 'middleman-cdn'
  s.version     = Middleman::CDN::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Leigh McCulloch"]
  s.licenses    = ["MIT"]
  s.homepage    = "https://github.com/leighmcculloch/middleman-cdn"
  s.summary     = %q{Invalidate CloudFlare, AWS CloudFront, Rackspace, Fastly, or MaxCDN cache after deployment}
  s.description = %q{Invalidate a specific set of files in your CloudFlare, AWS CloudFront, Rackspace, Fastly, or MaxCDN cache}

  s.files         = `git ls-files -z`.split("\0")
  s.require_paths = ["lib"]

  s.add_dependency 'fog-aws', '~> 1.4'
  s.add_dependency 'cloudflare', '~> 3.2.1'
  s.add_dependency 'fastly', '~> 1.1'
  s.add_dependency 'maxcdn', '~> 0.1'
  s.add_dependency 'ansi', '~> 1.5'
  s.add_dependency 'activesupport', '>= 4.1'
  s.add_dependency 'httparty', '~> 0.13'

  s.add_development_dependency 'rake', '~> 0.9'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'coveralls', '~> 0.7'
  s.add_development_dependency 'appraisal', '~> 2.1'

  s.add_dependency 'middleman', '>= 3.2'
end
