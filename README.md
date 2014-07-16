# Middleman CDN [![Build Status](https://travis-ci.org/leighmcculloch/middleman-cdn.svg)](https://travis-ci.org/leighmcculloch/middleman-cdn) [![Dependency Status](https://gemnasium.com/leighmcculloch/middleman-cdn.png)](https://gemnasium.com/leighmcculloch/middleman-cdn)

**Build status failing due to [RubyGem's issues affecting some gems](https://twitter.com/rubygems_status/statuses/489119131862462464). Tests do pass.**

A [middleman](http://middlemanapp.com/) deploy tool for invalidating resources cached
on common Content Delivery Networks (CDNs).

* Cache invalidation of files on:
  * [CloudFlare](https://cloudflare.com)
  * [Fastly](https://fastly.com)
  * [Amazon CloudFront](http://aws.amazon.com/cloudfront/)
* Select files for invalidation with regex.  
* Automatically invalidate after build.
* Manually trigger invalidation with single command.

What's next?

* Add support for MaxCDN.
* Add support for RackspaceCDN (Akamai).
* [Open an issue](../../issues/new) if you'd like your CDN provider added.

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

Edit your middleman `config.rb` and add the following. Specify either one or
more CDN configurations.
```ruby
activate :cdn do |cdn|
  cdn.cloudflare = {
    client_api_key: '...',          # default ENV['CLOUDFLARE_CLIENT_API_KEY']
    email: 'you@example.com',       # default ENV['CLOUDFLARE_EMAIL']
    zone: 'example.com',
    base_urls: [
      'http://example.com',
      'https://example.com',
    ]
  }
  cdn.fastly = {
    api_key: '...',                 # default ENV['FASTLY_API_KEY']
    base_urls: [
      'http://www.example.com',
      'https://www.example.com'
    ],
  }
  cdn.cloudfront = {
    access_key_id: '...',           # default ENV['AWS_ACCESS_KEY_ID']
    secret_access_key: '...',       # default ENV['AWS_SECRET_ACCESS_KEY']
    distribution_id: '...'
  }
  cdn.filter            = /\.html/i # default /.*/
  cdn.after_build       = true      # default is false
end
```

### Configuration: Filter

The `filter` parameter defines which files in your middleman `build` directory
will be invalidated on the CDN. It must be a regular expression (use
[rubular](http://rubular.com/) to test your regex).  

Examples:

| Files         | Regex         |
|:------------- |:------------- |
| HTML files    | `/\.html$/i`  |
| All files     | `/.*/`        |

It's better to always invalidate only the files you need. If you're using
[middleman's asset pipeline](http://middlemanapp.com/basics/asset-pipeline/) to
generate fingerprinted CSS, JS and images, then you should never need to
invalidate them.

Note: Directories containing `index.html` files are automatically included
when their respective `index.html` is included in the filter.

### Configuration: CloudFlare

The `cloudflare` parameter contains the information specific to your CloudFlare
account and which zone (domain) files should be invalidated for. CloudFlare
invalidation works off URLs not filenames, and you must provide a list of
base urls to ensure we invalidate every URL that your files might be accessed
at.

| Parameter | Description |
|:--------- |:----------- |
| `client_api_key` | You can find this by logging into CloudFlare, going to your account page and it will be down the bottom left. |
| `email` | The email address that you use to login to CloudFlare with. |
| `zone` | The domain name of the website we are invalidating. |
| `base_urls` | An array of base URLs that the files are accessible at. |

CloudFlare invalidations often take a few seconds.

### Configuration: Fastly

The `fastly` parameter contains the information specific to your Fastly
account. Fastly invalidation works off URLs not filenames, and you must provide
a list of base urls to ensure we invalidate every URL that your files might be
at.

| Parameter | Description |
|:--------- |:----------- |
| `api_key` | You can find this by logging into Fastly, going to your account page and it will be on the left. |
| `base_urls` | An array of base URLs that the files are accessible at. |

Fastly invalidations often take a few seconds.

### Configuration: CloudFront

The `cloudfront` parameter contains the information specific to your AWS CloudFront
account and which distribution files should be invalidated for.

| Parameter | Description |
|:--------- |:----------- |
| `access_key_id` | AWS Access Key ID (generate in AWS Console IAM) |
| `secret_access_key` | AWS Secret Access Key (generate in AWS Console IAM) |
| `distribution_id` | The distribution ID on the CloudFront distribution. |

CloudFront invalidations take up to 15 minutes. You can monitor the progress of
the invalidation in your AWS Console.

### Credentials via Environment Variables

Instead of storing your CDN credentials in config.rb where they may be public
on github, store them in environment variables, or execute on the
commandline as:

```bash
CLOUDFLARE_CLIENT_API_KEY= CLOUDFLARE_EMAIL= FASTLY_API_KEY= AWS_ACCESS_KEY= AWS_SECRET= bundle exec middleman invalidate
```

## Invalidating

Set `after_build` to `true` and the cache will be invalidated after build:  
```bash
bundle exec middleman build
```

Or, invalidate manually using:  
```bash
bundle exec middleman cdn_invalidate
```

Or:
```bash
bundle exec middleman cdn
```

## Example Usage

I'm using middleman-cdn on my personal website [leighmcculloch.com](http://leighmcculloch.com) which is on [github](https://github.com/leighmcculloch/leighmcculloch.com) if you want to checkout how I deploy. Unlike CloudFront, CloudFlare doesn't default to caching HTML. Configure a PageRule that looks like this to tell CloudFlare's edge to cache everything.  
![CloudFlare PageRule Example](README-cloudflare-pagerule-example.png)

## Thanks

Middleman CDN is a fork off [Middleman CloudFront](https://github.com/andrusha/middleman-cloudfront) and I used it as the base for building this extension. The code was well structured and easy to understand. It was easy to break out the CloudFront specific logic and to add support for CloudFlare. My gratitude goes to @andrusha and his work on Middleman CloudFront.

Thanks to @b4k3r for the [Cloudflare gem](https://github.com/b4k3r/cloudflare) that made invalidating CloudFlare files a breeze.

## Why Middleman CDN

Middleman CloudFront is a great extension for Middleman and perfect if you're using CloudFront. I needed a similar extension for CloudFlare, however it's becoming increasingly common for static websites to be hosted across multiple CDNs. [jsDelivr](http://jsdelivr.com/) is a well known promoter of this strategy.  

In light of the new trends in how we are using CDNs, I decided it would be more worthwhile to create an extension that can grow to support all the popular CDNs.
