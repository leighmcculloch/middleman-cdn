require "httparty"
require "active_support/core_ext/string"
require "middleman-cdn/clients/rackspace.rb"

module Middleman
  module Cli
    class RackspaceCDN < BaseCDN
      DAILY_LIMIT = 25

      def self.key
        "rackspace"
      end

      def self.example_configuration_elements
        {
          username: ['"..."', "# default ENV['RACKSPACE_USERNAME']"],
          api_key: ['"..."', "# default ENV['RACKSPACE_API_KEY']"],
          region: ['"DFW"', "# DFW, SYD, IAD, ORD, HKG, etc"],
          container: ['"..."', ""],
          notification_email: ['"..."', "# optional"],
        }
      end

      def invalidate(options, files, all: false)
        options[:username] ||= ENV['RACKSPACE_USERNAME']
        options[:api_key] ||= ENV['RACKSPACE_API_KEY']

        [:username, :api_key, :region, :container].each do |key|
          if options[key].blank?
            say_status(ANSI.red{ "Error: Configuration key rackspace[:#{key}] is missing." })
            raise
          end
        end

        files = files.reject { |file| file.end_with?("/") }

        if files.count > DAILY_LIMIT
          say_status("Warning: You are invalidating more files than Rackspace's daily limit (25).")
          say_status("Press ENTER to continue, or CTRL-C to exit.", wait_enter: true)
        end

        rackspace_client = RackspaceClient.new(options[:username], options[:api_key])

        files.each do |file| 
          invalidate_file(rackspace_client, options[:region], options[:container], file, notification_email: options[:notification_email])
        end
      end

      private

      def invalidate_file(rackspace_client, region, container, file, notification_email: nil)
        begin
          say_status("Invalidating #{file}...", newline: false)
          rackspace_client.invalidate(region, container, file, notification_email: notification_email)
        rescue => e
          say_status(ANSI.red{ " error: #{e.message}" }, header: false)
        else
          say_status(ANSI.green{ "✔" }, header: false)
        end
      end
    end
  end
end
