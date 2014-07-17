require 'coveralls'
Coveralls.wear!

require 'middleman-cdn'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end

Fog.mock!
