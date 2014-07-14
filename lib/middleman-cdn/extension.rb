require 'middleman-core'

module Middleman
  module CDN
    module Helpers
      def cdn_options
        ::Middleman::CDN::CDNExtension.options
      end
    end

    class CDNExtension < Middleman::Extension
      option :cloudflare, nil, 'CloudFlare options'
      option :cloudfront, nil, 'CloudFront options'
      option :filter, nil, 'Cloudflare options'
      option :after_build, false, 'Cloudflare options'

      def initialize(app, options_hash = {}, &block)
        super

        @@cdn_options = options

        app.after_configuration do
          app.after_build do
            ::Middleman::Cli::CDN.new.invalidate(@@cdn_options) if @@cdn_options.after_build
          end
        end

        app.send :include, Helpers
      end

      def registered
        included
      end

      def self.options
        @@cdn_options
      end

    end
  end
end
