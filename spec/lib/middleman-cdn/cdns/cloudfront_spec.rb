require 'spec_helper'
require 'lib/middleman-cdn/cdns/base_protocol'

describe Middleman::Cli::CloudFrontCDN do
  it_behaves_like "BaseCDN"

  describe '.key' do
    it "should be 'cloudfront'" do
      expect(described_class.key).to eq("cloudfront")
    end
  end
end
