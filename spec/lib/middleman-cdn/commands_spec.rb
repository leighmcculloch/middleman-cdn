require 'spec_helper'

require 'fog/aws/models/cdn/distributions'

describe Middleman::Cli::CDN do
  let(:cdn) { described_class.new }
  let(:options) do
    Middleman::CDN::Options.new(
      'access_key_id_123',
      'secret_access_key_123',
      'distribution_id_123',
      'filter_123',
      'after_build_123'
    )
  end
  let(:distribution) { double('distribution', invalidations: double('invalidations')) }

  describe '#invalidate' do
    before do
      allow_any_instance_of(Fog::CDN::AWS::Distributions).to receive(:get).and_return(distribution)
      allow(distribution.invalidations).to receive(:create) do
        double('invalidation', status: 'InProgress', wait_for: ->{} )
      end
    end

    it 'gets the correct distribution' do
      allow(cdn).to receive(:list_files).and_return []
      expect_any_instance_of(Fog::CDN::AWS::Distributions).to receive(:get).with('distribution_id_123')
      cdn.invalidate(options)
    end

    context 'when the amount of files to invalidate is under the limit' do
      it 'divides them up in packages and creates one invalidation per package' do
        files = (1..Middleman::Cli::CDN::INVALIDATION_LIMIT).map do |i|
          "file_#{i}"
        end
        allow(cdn).to receive(:list_files).and_return files
        expect(distribution.invalidations).to receive(:create).once.with(paths: files)
        cdn.invalidate(options)
      end
    end

    context 'when the amount of files to invalidate is over the limit' do
      it 'creates only one invalidation with all of them' do
        files = (1..(Middleman::Cli::CDN::INVALIDATION_LIMIT * 3)).map do |i|
          "file_#{i}"
        end
        allow(cdn).to receive(:list_files).and_return files
        expect(distribution.invalidations).to receive(:create).once.with(paths: files[0, Middleman::Cli::CDN::INVALIDATION_LIMIT])
        expect(distribution.invalidations).to receive(:create).once.with(paths: files[Middleman::Cli::CDN::INVALIDATION_LIMIT, Middleman::Cli::CDN::INVALIDATION_LIMIT])
        expect(distribution.invalidations).to receive(:create).once.with(paths: files[Middleman::Cli::CDN::INVALIDATION_LIMIT * 2, Middleman::Cli::CDN::INVALIDATION_LIMIT])
        cdn.invalidate(options)
      end
    end
  end
end
