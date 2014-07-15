#Encoding: UTF-8
require "cloudflare"
require "active_support/core_ext/string"

module Middleman
  module Cli

    class CloudFlareCDN < BaseCDN
      def self.key
        "cloudflare"
      end

      def self.example_configuration_elements
        {
          client_api_key: ['"..."', "# default ENV['CLOUDFLARE_CLIENT_API_KEY']"],
          email: ['"..."', "# default ENV['CLOUDFLARE_EMAIL']"],
          zone: ['"..."', ""],
          base_urls: [['http://example.com', 'https://example.com'], ""]
        }
      end

      def invalidate(options, files)
        options[:client_api_key] ||= ENV['CLOUDFLARE_CLIENT_API_KEY']
        options[:email] ||= ENV['CLOUDFLARE_EMAIL']

        [:client_api_key, :email, :zone, :base_urls].each do |key|
          if options[key].blank?
            say_status("Error: Configuration key cloudflare[:#{key}] is missing.".light_red)
            raise
          end
        end

        options[:base_urls] = [options[:base_urls]] if options[:base_urls].is_a?(String)
        if !options[:base_urls].is_a?(Array)
          say_status("Error: Configuration key cloudflare[:base_urls] must be an array and contain at least one base url.".light_red)
          raise
        end

        cloudflare = ::CloudFlare::connection(options[:client_api_key], options[:email])
        options[:base_urls].each do |base_url|
          files.each do |file|
            begin
              url = "#{base_url}#{file}"
              say_status("Invalidating #{url}... ", newline: false)
              cloudflare.zone_file_purge(options[:zone], "#{base_url}#{file}")
            rescue => e
              say_status(", " + "error: #{e.message}".light_red, header: false)
            else
              say_status("✔".light_green, header: false)
            end
          end
        end
      end
    end

  end
end
