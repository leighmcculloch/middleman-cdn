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

  describe '#invalidate' do
    let(:options) do
      {
        access_key_id: 'access_key_id_123',
        secret_access_key: 'secret_access_key_123',
        distribution_id: 'distribution_id_123'
      }
    end

    before do
      allow_any_instance_of(Fog::CDN::AWS::Distributions).to receive(:get).and_return(distribution)
      allow(distribution.invalidations).to receive(:create) do
        double('invalidation', status: 'InProgress', wait_for: ->{} )
      end
    end

    it 'gets the correct distribution' do
      allow(cdn).to receive(:list_files).and_return ['index.html']
      expect_any_instance_of(Fog::CDN::AWS::Distributions).to receive(:get).with('distribution_id_123')
      cdn.invalidate(options)
    end

    context 'when the amount of files to invalidate is under the limit' do
      it 'divides them up in packages and creates one invalidation per package' do
        files = (1..Middleman::Cli::CloudFrontCDN::INVALIDATION_LIMIT).map do |i|
          "file_#{i}"
        end
        allow(cdn).to receive(:list_files).and_return files
        expect(distribution.invalidations).to receive(:create).once.with(paths: files)
        cdn.invalidate(options)
      end
    end

    context 'when the amount of files to invalidate is over the limit' do
      it 'creates only one invalidation with all of them' do
        files = (1..(Middleman::Cli::CloudFrontCDN::INVALIDATION_LIMIT * 3)).map do |i|
          "file_#{i}"
        end
        allow(cdn).to receive(:list_files).and_return files
        expect(distribution.invalidations).to receive(:create).once.with(paths: files[0, Middleman::Cli::CloudFrontCDN::INVALIDATION_LIMIT])
        expect(distribution.invalidations).to receive(:create).once.with(paths: files[Middleman::Cli::CloudFrontCDN::INVALIDATION_LIMIT, Middleman::Cli::CloudFrontCDN::INVALIDATION_LIMIT])
        expect(distribution.invalidations).to receive(:create).once.with(paths: files[Middleman::Cli::CloudFrontCDN::INVALIDATION_LIMIT * 2, Middleman::Cli::CloudFrontCDN::INVALIDATION_LIMIT])
        cdn.invalidate(options)
      end
    end
  end
end
