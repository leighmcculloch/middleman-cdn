require 'spec_helper'
require 'lib/middleman-cdn/cdns/base_protocol'

shared_examples "invalidating the entire zone" do
  before do
    allow(double_cloudflare).to receive(:fpurge_ts)
  end

  it "should invalidate the entire zone" do
    expect(double_cloudflare).to receive(:fpurge_ts).once.with("example.com")
    subject.invalidate(options, files, all: all)
  end

  it "should not invalidate individual files" do
    expect(double_cloudflare).to_not receive(:zone_file_purge)
    subject.invalidate(options, files, all: all)
  end
end

shared_examples "invalidating individual files" do
  it "should not invalidate the entire zone" do
    expect(double_cloudflare).to_not receive(:fpurge_ts)
    subject.invalidate(options, files, all: all)
  end

  it "should invalidate individual files" do
    files.each do |file|
      expect(double_cloudflare).to receive(:zone_file_purge).once.ordered.with("example.com", "http://example.com#{file}")
    end
    subject.invalidate(options, files, all: all)
  end
end

describe Middleman::Cli::CloudFlareCDN do
  it_behaves_like "BaseCDN"

  describe '.key' do
    it "should be 'cloudflare'" do
      expect(described_class.key).to eq("cloudflare")
    end
  end

  describe '.example_configuration_elements' do
    it "should contain these keys" do
      required_keys = [:client_api_key, :email, :zone, :base_urls, :invalidate_zone_for_many_files]
      expect(described_class.example_configuration_elements.keys).to eq(required_keys)
    end
  end

  describe '#invalidate' do
    let(:double_cloudflare) { double("::Cloudflare") }

    before do
      allow(double_cloudflare).to receive(:zone_file_purge)
      allow(::Cloudflare).to receive(:connection).and_return(double_cloudflare)
    end

    let(:files) { (1..50).map { |i| "/test/file_#{i}.txt" } }
    let(:all) { false }

    context "all options provided" do
      let(:options) do
        {
          client_api_key: '000000000000000000000',
          email: 'test@example.com',
          zone: 'example.com',
          base_urls: ['http://example.com', 'https://example.com']
        }
      end

      it "should connect to cloudflare with credentails" do
        expect(::Cloudflare).to receive(:connection).with("000000000000000000000", "test@example.com")
        subject.invalidate(options, files)
      end

      it "should not raise errors" do
        subject.invalidate(options, files)
      end

      it "should output saying invalidating each file checkmarks" do
        files_escaped = files.map { |file| Regexp.escape(file) }
        expect { subject.invalidate(options, files) }.to output(/#{files_escaped.join(".+")}/m).to_stdout
      end

      it "should output indicating invalidating on all base urls" do
        base_urls_escaped = options[:base_urls].map { |base_url| Regexp.escape(base_url) }
        expect { subject.invalidate(options, files) }.to output(/#{base_urls_escaped.join(".+")}/m).to_stdout
      end

      it "should output saying success checkmarks" do
        expect { subject.invalidate(options, files) }.to output(/✔/).to_stdout
      end

      context "max 50 files to invalidate" do
        before do
          expect(files.count).to be <= 50
        end

        it_behaves_like "invalidating individual files"

        it "should call cloudflare to purge each file for each base url" do
          files.each do |file|
            expect(double_cloudflare).to receive(:zone_file_purge).once.ordered.with("example.com", "http://example.com#{file}")
          end
          subject.invalidate(options, files)
        end
      end

      context "more than 50 files to invalidate" do
        let(:files) { super() + ["/index.html"] }

        before do
          expect(files.count).to be > 50
        end

        context "invalidate_zone_for_many_files is not set" do
          before do
            expect(options.key?(:invalidate_zone_for_many_files)).to be_falsy
          end

          it_behaves_like "invalidating the entire zone"
        end

        context "invalidate_zone_for_many_files is set to true" do
          let(:options) { super().merge(invalidate_zone_for_many_files: true) }

          it_behaves_like "invalidating the entire zone"
        end

        context "invalidate_zone_for_many_files is set to false" do
          let(:options) { super().merge(invalidate_zone_for_many_files: false) }

          it_behaves_like "invalidating individual files"
        end
      end

      context "matching all files" do
        let(:all) { true }

        it_behaves_like "invalidating the entire zone"
      end

      context "and errors occurs when purging" do
        before do
          allow(double_cloudflare).to receive(:zone_file_purge).and_raise(StandardError)
        end

        it "should output saying error information" do
          expect { subject.invalidate(options, files) }.to output(/error: StandardError/).to_stdout
        end
      end
    end

    context "environment variables used for credentials" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("CLOUDFLARE_CLIENT_API_KEY").and_return("111111111111111111111")
        allow(ENV).to receive(:[]).with("CLOUDFLARE_EMAIL").and_return("test-env@example.com")
      end

      let(:options) do
        {
          zone: 'example.com',
          base_urls: ['http://example.com', 'https://example.com']
        }
      end

      it "should connect to cloudflare with environment variable credentails" do
        expect(::Cloudflare).to receive(:connection).with("111111111111111111111", "test-env@example.com")
        subject.invalidate(options, files)
      end

      it "should not raise errors" do
        subject.invalidate(options, files)
      end
    end

    context "if client_api_key not provided" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("CLOUDFLARE_CLIENT_API_KEY").and_return(nil)
      end

      let(:options) do
        {
          email: 'test@example.com',
          zone: 'example.com',
          base_urls: ['http://example.com', 'https://example.com']
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key cloudflare\[:client_api_key\] is missing\./).to_stdout
      end
    end

    context "if email not provided" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("CLOUDFLARE_EMAIL").and_return(nil)
      end

      let(:options) do
        {
          client_api_key: '000000000000000000000',
          zone: 'example.com',
          base_urls: ['http://example.com', 'https://example.com']
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key cloudflare\[:email\] is missing\./).to_stdout
      end
    end

    context "if zone not provided" do
      let(:options) do
        {
          client_api_key: '000000000000000000000',
          email: 'test@example.com',
          base_urls: ['http://example.com', 'https://example.com']
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key cloudflare\[:zone\] is missing\./).to_stdout
      end
    end

    context "if base_urls not provided" do
      let(:options) do
        {
          client_api_key: '000000000000000000000',
          email: 'test@example.com',
          zone: 'example.com',
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key cloudflare\[:base_urls\] is missing\./).to_stdout
      end
    end

    context "if base_urls is a String" do
      let(:options) do
        {
          client_api_key: '000000000000000000000',
          email: 'test@example.com',
          zone: 'example.com',
          base_urls: 'http://sub.example.com'
        }
      end

      it "should not raise error" do
        expect { subject.invalidate(options, files) }.to_not raise_error
      end

      it "should output indicating invalidating on the one base url" do
        base_url_escaped = Regexp.escape(options[:base_urls])
        expect { subject.invalidate(options, files) }.to output(/#{base_url_escaped}/).to_stdout
      end
    end

    context "if base_urls is an empty Array" do
      let(:options) do
        {
          client_api_key: '000000000000000000000',
          email: 'test@example.com',
          zone: 'example.com',
          base_urls: []
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key cloudflare\[:base_urls\] is missing\./).to_stdout
      end
    end

    context "if base_urls is not an Array or String" do
      let(:options) do
        {
          client_api_key: '000000000000000000000',
          email: 'test@example.com',
          zone: 'example.com',
          base_urls: 200
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key cloudflare\[:base_urls\] must be an array and contain at least one base url\./).to_stdout
      end
    end
  end
end
