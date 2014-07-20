module Middleman
  module Cli

    class BaseCDN
      def self.example_configuration
        config_lines = self.example_configuration_elements.map do |config_key, config_info|
          "    #{config_key.to_s}: #{config_info[0]},".ljust(30) + " #{config_info[1]}"
        end

        <<-TEXT
  cdn.#{self.key} = {
#{config_lines.join("\n")}
  }
        TEXT
      end

      def say_status(status, newline: true, header: true, wait_enter: false)
        ::Middleman::Cli::CDN.say_status(self.class.key, status, newline: newline, header: header, wait_enter: wait_enter)
      end
    end

  end
end
