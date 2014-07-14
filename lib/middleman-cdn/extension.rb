require 'middleman-core'

module Middleman
  module CDN
    class Options < Struct.new(:cloudfront, :filter, :after_build); end

    class << self
      def options
        @@cdn_options
      end

      def registered(app, options_hash = {}, &block)
        @@cdn_options = Options.new(options_hash)
        yield @@cdn_options if block_given?

        app.after_build do
          ::Middleman::Cli::CDN.new.invalidate(@@cdn_options) if @@cdn_options.after_build
        end

        app.send :include, Helpers
      end
      alias :included :registered
    end

    module Helpers
      def cdn_options
        ::Middleman::CDN.options
      end
    end

  end
end
