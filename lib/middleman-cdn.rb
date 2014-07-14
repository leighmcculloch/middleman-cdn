require 'middleman-core'
require 'middleman-cdn/commands'

::Middleman::Extensions.register(:cdn, ">= 3.0.0") do
  require "middleman-cdn/extension"
  ::Middleman::CDN
end
