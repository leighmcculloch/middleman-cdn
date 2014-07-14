require "middleman-core/cli"
require "middleman-cdn/extension"
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

        if options.cloudfront.nil?
          raise Error, "ERROR: You must specify a config for cloudfront.\n#{example_configuration}"
        end

        # CloudFront limits the amount of files which can be invalidated by one request to 1000.
        # If there are more than 1000 files to invalidate, do so sequentially and wait until each validation is ready.
        # If there are max 1000 files, create the invalidation and return immediately.
        files = list_files(options.filter)
        return if files.empty?

        CloudFrontCDN.new.invalidate(options, files) if options.cloudfront
      end

      protected

      def example_configuration
        <<-TEXT

The example configuration is:
activate :cdn do |cdn|
#{CloudFrontCDN.example_configuration}
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
