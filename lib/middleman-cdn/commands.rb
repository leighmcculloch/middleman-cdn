require "middleman-core/cli"
require "middleman-cdn/extension"
require "middleman-cdn/cdns/base.rb"
require "middleman-cdn/cdns/cloudflare.rb"
require "middleman-cdn/cdns/cloudfront.rb"
require "middleman-cdn/cdns/fastly.rb"
require "middleman-cdn/cdns/maxcdn.rb"
require "middleman-cdn/cdns/rackspace.rb"
require "ansi/code"

module Middleman
  module Cli

    class CDN < Thor::Group
      include Thor::Actions

      check_unknown_options!

      namespace :cdn_invalidate

      def self.exit_on_failure?
        true
      end

      def cdn_invalidate(*args)
        begin
          options, files = if args.first && args.first.respond_to?(:filter)
            [args.first, args.drop(1)]
          else
            [Middleman::CDN::Extension.options, args]
          end

          if options.nil?
            self.class.say_status(nil, ANSI.red{ "Error: You need to activate the cdn extension in config.rb.\n#{example_configuration}" })
            return
          end
          options.filter ||= /.*/

          if cdns.all? { |cdn| options.public_send(cdn.key.to_sym).nil? }
            self.class.say_status(nil, ANSI.red{ "Error: You must specify a config for one of the supported CDNs.\n#{example_configuration}" })
            raise
          end

          unless files.empty?
            files = normalize_files(files)
            message = "Invalidating #{files.count} files:"
          else
            files = normalize_files(list_files(options.filter))
            message = "Invalidating #{files.count} files with filter: #{options.filter.source}"
          end
          self.class.say_status(nil, message)
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
        message << "#{ANSI.green { :cdn.to_s.rjust(12)} }  #{ANSI.yellow{ cdn } unless cdn.nil? }" if header
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
        normalized_files = []

        # Add directories of index.html files since they have to be
        # invalidated as well if :directory_indexes is active
        files.each do |file|
          normalized_files << file

          # For /dir/index.html add /dir/
          file_dir = file.sub(/\bindex\.html\z/, '')
          normalized_files << file_dir if file_dir != file

          # For /dir/index.html add /dir
          file_dir_no_slash = file.sub(/\/index\.html\z/, '')
          normalized_files << file_dir_no_slash if file_dir_no_slash != file
        end

        # Add leading slash
        normalized_files.map { |f| f.start_with?('/') ? f : "/#{f}" }
      end

      Base.register(self, 'cdn_invalidate', 'cdn_invalidate [options]', 'Invalidate CDN')

      Base.map('cdn' => 'cdn_invalidate')
    end
  end
end
