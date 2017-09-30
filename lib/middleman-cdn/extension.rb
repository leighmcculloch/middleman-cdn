require 'middleman-core'

module Middleman
  module CDN
    class Extension < Middleman::Extension
      option :cloudflare, nil, 'CloudFlare options'
      option :cloudfront, nil, 'CloudFront options'
      option :fastly, nil, 'Fastly options'
      option :maxcdn, nil, 'MaxCDN options'
      option :rackspace, nil, 'Rackspace options'
      option :filter, nil, 'Filter files to invalidate'
      option :after_build, false, 'Invalidate automatically after build'

      @@cdn_options = nil

      def initialize(app, options_hash = {}, &block)
        super

        @@cdn_options = options
      end

      def self.options
        @@cdn_options
      end

      def after_build(builder)
        ::Middleman::Cli::CDN.new.cdn_invalidate(options) if options.after_build
      end

      helpers do
        def cdn_invalidate(files = nil)
          ::Middleman::Cli::CDN.new.cdn_invalidate(cdn_options, *files)
        end

        def cdn_options
          ::Middleman::CDN::Extension.options
        end
      end
    end
  end
end
