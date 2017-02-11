require "fastly"
require "active_support/core_ext/string"

module Middleman
  module Cli

    class FastlyCDN < BaseCDN
      def self.key
        "fastly"
      end

      def self.example_configuration_elements
        {
          api_key: ['"..."', "# default ENV['FASTLY_API_KEY']"],
          base_urls: [['http://www.example.com', 'https://www.example.com'], ""]
        }
      end

      def invalidate(options, files, all: false)
        options[:api_key] ||= ENV['FASTLY_API_KEY']

        [:api_key, :base_urls].each do |key|
          if options[key].blank?
            say_status(ANSI.red{ "Error: Configuration key fastly[:#{key}] is missing." })
            raise
          end
        end

        options[:base_urls] = [options[:base_urls]] if options[:base_urls].is_a?(String)
        if !options[:base_urls].is_a?(Array)
          say_status(ANSI.red{ "Error: Configuration key fastly[:base_urls] must be an array and contain at least one base url." })
          raise
        end

        fastly = ::Fastly.new({
          :api_key => options[:api_key]
        })

        options[:base_urls].each do |base_url|
          files.each do |file|
            begin
              url = "#{base_url}#{file}"
              say_status("Invalidating #{url}... ", newline: false)
              fastly.purge("#{base_url}#{file}")
            rescue => e
              say_status(ANSI.red{ ", " + "error: #{e.message}" }, header: false)
            else
              say_status(ANSI.green{ "✔" }, header: false)
            end
          end
        end
      end
    end

  end
end
