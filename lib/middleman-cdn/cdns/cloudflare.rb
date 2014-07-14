#Encoding: UTF-8
require "cloudflare"
require "active_support/core_ext/string"

module Middleman
  module Cli

    class CloudFlareCDN
      def self.key
        "cloudflare"
      end

      def self.example_configuration
        <<-TEXT
  cdn.cloudflare = {
    client_api_key: 'I',         # default ENV['CLOUDFLARE_CLIENT_API_KEY']
    email: 'love',               # default ENV['CLOUDFLARE_EMAIL']
    zone: 'cats',
    base_urls: ['http://example.com', 'https://example.com']
  }
TEXT
      end

      def invalidate(options, files)
        puts "## Invalidating files on CloudFlare"

        options[:client_api_key] ||= ENV['CLOUDFLARE_CLIENT_API_KEY']
        options[:email] ||= ENV['CLOUDFLARE_EMAIL']
        [:client_api_key, :email, :zone, :base_urls].each do |key|
          raise StandardError, "Configuration key cloudflare[:#{key}] is missing." if options[key].blank?
        end
        if options[:base_urls].is_a?(String)
          options[:base_urls] = [options[:base_urls]]
        end
        if !options[:base_urls].is_a?(Array) || options[:base_urls].length == 0
          raise StandardError, "Configuration key cloudfront[:base_urls] is missing."
        end

        options[:base_urls].each do |base_url|
          files.each do |file|
            cloudflare = ::CloudFlare::connection(options[:client_api_key], options[:email])
            begin
              url = "#{base_url}#{file}"
              print "Invalidating #{url}... "
              cloudflare.zone_file_purge(options[:zone], "#{base_url}#{file}")
            rescue => e
              puts "Error: #{e.message}"
            else
              puts "✓"
            end
          end
        end
      end
    end

  end
end
