# Middleman CDN [![Build Status](https://travis-ci.org/leighmcculloch/middleman-cdn.svg)](https://travis-ci.org/leighmcculloch/middleman-cdn) [![Dependency Status](https://gemnasium.com/leighmcculloch/middleman-cdn.png)](https://gemnasium.com/leighmcculloch/middleman-cdn)
A deploying tool for middleman which allows you to invalidate resources cached
on the CloudFlare and Amazon CloudFront CDNs. Specifically useful if your
using multiple CDNs to cache the content of your middleman website.

* Cache invalidation of files on:
  * CloudFlare
  * Amazon CloudFront
  * **Use another CDN? Open an issue and I'll do it.**
* Invalidate files on multiple CDNs.
* Call from the command line.
* Call automatically after middleman build.  
* Ability to select/filter files to be invalidated by regex.  

What's next?

* Expand the test base.
* Add support for Fastly.
* Add support for MaxCDN.

# Usage

## Installation
Add this to your `Gemfile`:  
```ruby
gem "middleman-cdn"
```

Then run:  
```
bundle install
```

## Configuration

Edit `config.rb` and add the following. Specify either one CDN config or
multiple.  
```ruby
activate :cdn do |cdn|
  cdn.cloudflare = {
    client_api_key: '...',         # default ENV['CLOUDFLARE_CLIENT_API_KEY']
    email: 'you@example.com',      # default ENV['CLOUDFLARE_EMAIL']
    zone: 'example.com',
    base_urls: ['http://example.com', 'https://example.com']
  }
  cdn.cloudfront = {
    access_key_id: '...',           # default ENV['AWS_ACCESS_KEY_ID']
    secret_access_key: '...',       # default ENV['AWS_SECRET_ACCESS_KEY']
    distribution_id: '...'
  }
  cdn.filter            = /\.html/i # default /.*/
  cdn.after_build       = true     # default is false
end
```

Instead of storing your CDN credentials in config.rb store them in the
environment variables specified above, or execute on the commandline as:

```bash
CLOUDFLARE_CLIENT_API_KEY= CLOUDFLARE_EMAIL= AWS_ACCESS_KEY= AWS_SECRET= bundle exec middleman invalidate
```

## Invalidating

Set `after_build` to `true` and the cache will be invalidated after build:  
```bash
bundle exec middleman build
```

Otherwise, invalidate manually using:  
```bash
bundle exec middleman invalidate
```

Or, shorthand:  
```bash
bundle exec middleman inv
```

## In the wild

I'm using middleman-cdn on my personal website leighmcculloch.com on github.

## Thanks

Middleman CDN is a fork off [Middleman CloudFront](https://github.com/andrusha/middleman-cloudfront) and I used it as the base for building this extension. The code was well structured and easy to understand. It was easy to break out the CloudFront specific logic and to add support for CloudFlare. My gratitude goes to @andrusha and his work on Middleman CloudFront.

Thanks to @b4k3r for the [Cloudflare gem](https://github.com/b4k3r/cloudflare) that made invalidating CloudFlare files a breeze.

Thanks to @cloudflare for CloudFlare.
