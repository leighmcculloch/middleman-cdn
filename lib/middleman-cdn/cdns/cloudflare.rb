require "cloudflare"
require "active_support/core_ext/string"

module Middleman
  module Cli

    class CloudFlareCDN < BaseCDN
      INVALIDATE_ZONE_THRESHOLD = 50

      def self.key
        "cloudflare"
      end

      def self.example_configuration_elements
        {
          client_api_key: ['"..."', "# default ENV['CLOUDFLARE_CLIENT_API_KEY']"],
          email: ['"..."', "# default ENV['CLOUDFLARE_EMAIL']"],
          zone: ['"..."', ""],
          base_urls: [['http://example.com', 'https://example.com'], ""],
          invalidate_zone_for_many_files: [true, "# default true"]
        }
      end

      def invalidate(options, files, all: false)
        options[:invalidate_zone_for_many_files] = true unless options.key?(:invalidate_zone_for_many_files)
        options[:client_api_key] ||= ENV['CLOUDFLARE_CLIENT_API_KEY']
        options[:email] ||= ENV['CLOUDFLARE_EMAIL']

        [:client_api_key, :email, :zone, :base_urls].each do |key|
          if options[key].blank?
            say_status(ANSI.red{ "Error: Configuration key cloudflare[:#{key}] is missing." })
            raise
          end
        end

        options[:base_urls] = [options[:base_urls]] if options[:base_urls].is_a?(String)
        if !options[:base_urls].is_a?(Array)
          say_status(ANSI.red{ "Error: Configuration key cloudflare[:base_urls] must be an array and contain at least one base url." })
          raise
        end

        cloudflare = ::Cloudflare::connect(key: options[:client_api_key], email: options[:email])
        zone = cloudflare.zones.find_by_name(options[:zone])
        if all || (options[:invalidate_zone_for_many_files] && files.count > INVALIDATE_ZONE_THRESHOLD)
          begin
            say_status("Invalidating zone #{zone}... ", newline: false)
            zone.purge_cache
          rescue => e
            say_status(", " + ANSI.red{ "error: #{e.message}" }, header: false)
          else
            say_status(ANSI.green{ "✔" }, header: false)
          end
        else
          begin
            urls = options[:base_urls].map do |base_url|
              files.map { |file| "#{base_url}#{file}" }
            end

            say_status("Invalidating #{urls}... ", newline: false)
            zone.purge_cache(files: urls.flatten)
          rescue => e
            say_status(", " + ANSI.red{ "error: #{e.message}" }, header: false)
          else
            say_status(ANSI.green{ "✔" }, header: false)
          end
        end
      end
    end

  end
end
