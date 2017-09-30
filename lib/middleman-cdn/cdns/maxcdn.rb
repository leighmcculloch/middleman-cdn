require "maxcdn"
require "active_support/core_ext/string"

module Middleman
  module Cli

    class MaxCDN < BaseCDN
      def self.key
        "maxcdn"
      end

      def self.example_configuration_elements
        {
          alias: ['"..."', "# default ENV['MAXCDN_ALIAS']"],
          consumer_key: ['"..."', "# default ENV['MAXCDN_CONSUMER_KEY']"],
          consumer_secret: ['"..."', "# default ENV['MAXCDN_CONSUMER_SECRET']"],
          zone_id: ['"..."', ""]
        }
      end

      def invalidate(options, files, all: false)
        options[:alias] ||= ENV['MAXCDN_ALIAS']
        options[:consumer_key] ||= ENV['MAXCDN_CONSUMER_KEY']
        options[:consumer_secret] ||= ENV['MAXCDN_CONSUMER_SECRET']

        [:alias, :consumer_key, :consumer_secret, :zone_id].each do |key|
          if options[key].blank?
            say_status(ANSI.red{ "Error: Configuration key maxcdn[:#{key}] is missing." })
            raise
          end
        end

        maxcdn = ::MaxCDN::Client.new(options[:alias], options[:consumer_key], options[:consumer_secret])

        begin
          say_status("Invalidating #{files.count} files...", newline: false)
          maxcdn.purge(options[:zone_id], files)
        rescue => e
          say_status(ANSI.red{ ", " + "error: #{e.message}" }, header: false)
        else
          say_status(ANSI.green{ "✔" }, header: false)
        end
      end
    end

  end
end
