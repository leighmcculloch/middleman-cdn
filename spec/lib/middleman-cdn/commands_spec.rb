require 'spec_helper'
require 'fog/aws/models/cdn/distributions'

describe Middleman::Cli::CDN do
  let(:cdn) { described_class.new }
  let(:options) do
    OpenStruct.new({
      cloudflare: nil,
      cloudfront: {
        access_key_id: 'access_key_id_123',
        secret_access_key: 'secret_access_key_123',
        distribution_id: 'distribution_id_123',
      },
      filter: /.*/,
      after_build: 'after_build_123'
    })
  end
  let(:distribution) { double('distribution', invalidations: double('invalidations')) }

  describe '#invalidate' do
    # TODO
  end
end
