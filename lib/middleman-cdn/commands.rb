require "middleman-core/cli"
require "middleman-cdn/extension"
require "middleman-cdn/cdns/base.rb"
require "middleman-cdn/cdns/cloudflare.rb"
require "middleman-cdn/cdns/cloudfront.rb"
require "middleman-cdn/cdns/fastly.rb"
require "middleman-cdn/cdns/maxcdn.rb"
require "middleman-cdn/cdns/rackspace.rb"
require "colorize"

module Middleman
  module Cli

    class CDN < Thor
      include Thor::Actions

      check_unknown_options!

      namespace :cdn_invalidate

      def self.exit_on_failure?
        true
      end

      desc "cdn:cdn_invalidate", "Invalidate your CloudFlare or CloudFront cache"
      def cdn_invalidate(options = nil)
        begin
          if options.nil?
            app_instance = ::Middleman::Application.server.inst
            unless app_instance.respond_to?(:cdn_options)
              self.class.say_status(nil, "Error: You need to activate the cdn extension in config.rb.\n#{example_configuration}".red)
              raise
            end
            options = app_instance.cdn_options
          end
          options.filter ||= /.*/

          if cdns.all? { |cdn| options.public_send(cdn.key.to_sym).nil? }
            self.class.say_status(nil, "Error: You must specify a config for one of the supported CDNs.\n#{example_configuration}".red)
            raise
          end

          files = normalize_files(list_files(options.filter))
          self.class.say_status(nil, "Invalidating #{files.count} files with filter: " + "#{options.filter.source}".magenta.bold)
          files.each { |file| self.class.say_status(nil, " • #{file}") }
          return if files.empty?

          invalidate_all = does_filter_match_all(options.filter)

          cdns_keyed.each do |cdn_key, cdn|
            cdn_options = options.public_send(cdn_key.to_sym)
            cdn.new.invalidate(cdn_options, files, all: invalidate_all) unless cdn_options.nil?
          end
        rescue SystemExit, Interrupt
          self.class.say_status(nil, nil, header: false)
        end
      end

      def self.say_status(cdn, status, newline: true, header: true, wait_enter: false)
        message = ""
        message << "#{:cdn.to_s.rjust(12).green}  #{cdn.try(:yellow)}" if header
        message << " " if header && cdn
        message << status if status
        print message
        STDIN.noecho(&:gets) if wait_enter
        puts "" if newline
      end

      private

      def cdns
        [
          CloudFlareCDN,
          CloudFrontCDN,
          FastlyCDN,
          MaxCDN,
          RackspaceCDN
        ]
      end

      def cdns_keyed
        Hash[cdns.map { |cdn| [cdn.key, cdn] }]
      end

      def example_configuration
        <<-TEXT

Example configuration:
activate :cdn do |cdn|
#{cdns.map(&:example_configuration).join}
  cdn.filter            = /\.html/i  # default /.*/
  cdn.after_build       = true  # default is false
end
        TEXT
      end

      def does_filter_match_all(filter)
        [".*", ".+"].include?(filter.source)
      end

      def list_files(filter)
        Dir.chdir('build/') do
          Dir.glob('**/*', File::FNM_DOTMATCH).tap do |files|
            # Remove directories
            files.reject! { |f| File.directory?(f) }

            # Remove files that do not match filter
            files.reject! { |f| f !~ filter }
          end
        end
      end

      def normalize_files(files)
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

    Base.map({"cdn" => "cdn_invalidate"})
  end
end
