require 'spec_helper'
require 'lib/middleman-cdn/cdns/base_protocol'

describe Middleman::Cli::CloudFlareCDN do
  it_behaves_like "BaseCDN"

  describe '.key' do
    it "should be 'cloudflare'" do
      expect(described_class.key).to eq("cloudflare")
    end
  end
end
