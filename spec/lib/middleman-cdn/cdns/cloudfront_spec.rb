require 'spec_helper'
require 'lib/middleman-cdn/cdns/base_protocol'

describe Middleman::Cli::CloudFrontCDN do
  it_behaves_like "BaseCDN"

  describe '.key' do
    it "should be 'cloudfront'" do
      expect(described_class.key).to eq("cloudfront")
    end
  end

  describe '.example_configuration_elements' do
    it "should contain these keys" do
      required_keys = [:access_key_id, :secret_access_key, :distribution_id]
      expect(described_class.example_configuration_elements.keys).to eq(required_keys)
    end
  end
end
