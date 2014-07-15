require 'spec_helper'
require 'lib/middleman-cdn/cdns/base_protocol'

describe Middleman::Cli::CloudFlareCDN do
  it_behaves_like "BaseCDN"

  describe '.key' do
    it "should be 'cloudflare'" do
      expect(described_class.key).to eq("cloudflare")
    end
  end

  describe '.example_configuration_elements' do
    it "should contain these keys" do
      required_keys = [:client_api_key, :email, :zone, :base_urls]
      expect(described_class.example_configuration_elements.keys).to eq(required_keys)
    end
  end
end
