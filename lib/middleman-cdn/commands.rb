require "middleman-core/cli"
require "middleman-cdn/extension"
require "middleman-cdn/cdns/cloudflare.rb"
require "middleman-cdn/cdns/cloudfront.rb"

module Middleman
  module Cli

    class CDN < Thor
      include Thor::Actions

      check_unknown_options!

      namespace :invalidate

      def self.exit_on_failure?
        true
      end

      desc "cdn:invalidate", "A way to deal with your CloudFlare or CloudFront distributions"
      def invalidate(options = nil)
        if options.nil?
          app_instance = ::Middleman::Application.server.inst
          unless app_instance.respond_to?(:cdn_options)
            raise Error, "ERROR: You need to activate the cdn extension in config.rb.\n#{example_configuration}"
          end
          options = app_instance.cdn_options
        end
        options.filter ||= /.*/

        if cdns.all? { |cdn| options.public_send(cdn.key.to_sym).nil? }
          raise Error, "ERROR: You must specify a config for one of the supported CDNs.\n#{example_configuration}"
        end

        files = list_files(options.filter)
        ::Middleman::Cli::CDN.say_status("Invalidating #{files.count} files with filter: #{options.filter.source}")
        return if files.empty?

        cdns_keyed.each do |cdn_key, cdn|
          cdn_options = options.public_send(cdn_key.to_sym)
          cdn.new.invalidate(cdn_options, files) unless cdn_options.nil?
        end
      end

      def self.say_status(status, incomplete: false, header: true)
        message = ""
        message << :cdn.to_s.rjust(12).light_green + "  " if header
        message << status
        if incomplete
          print message
        else
          puts message
        end
      end

      protected

      def cdns
        [
          CloudFlareCDN,
          CloudFrontCDN
        ]
      end

      def cdns_keyed
        Hash[cdns.map { |cdn| [cdn.key, cdn] }]
      end

      def example_configuration
        <<-TEXT

The example configuration is:
activate :cdn do |cdn|
#{cdns.map(&:example_configuration).join}
  cdn.filter            = /\.html/i  # default /.*/
  cdn.after_build       = true  # default is false
end
        TEXT
      end

      def list_files(filter)
        Dir.chdir('build/') do
          Dir.glob('**/*', File::FNM_DOTMATCH).tap do |files|
            # Remove directories
            files.reject! { |f| File.directory?(f) }

            # Remove files that do not match filter
            files.reject! { |f| f !~ filter }

            # Add directories of index.html files since they have to be
            # invalidated as well if :directory_indexes is active
            files.each do |file|
              file_dir = file.sub(/\bindex\.html\z/, '')
              files << file_dir if file_dir != file
            end

            # Add leading slash
            files.map! { |f| f.start_with?('/') ? f : "/#{f}" }
          end
        end
      end

    end

    Base.map({"inv" => "invalidate"})
  end
end
