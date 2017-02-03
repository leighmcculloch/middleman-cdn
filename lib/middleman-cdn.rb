require 'middleman-core'
require 'middleman-cdn/commands'
require "middleman-cdn/extension"

::Middleman::Extensions.register(:cdn, ::Middleman::CDN::Extension)
