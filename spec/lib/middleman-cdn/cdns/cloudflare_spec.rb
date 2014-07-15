#Encoding: UTF-8
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

  describe '#invalidate' do
    let(:double_cloudflare) { double("::Cloudflare") }

    before do
      allow(double_cloudflare).to receive(:zone_file_purge)
      allow(::CloudFlare).to receive(:connection).and_return(double_cloudflare)
    end

    let(:files) { [ "/index.html", "/", "/test/index.html", "/test/image.png" ] }

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
        expect(::CloudFlare).to receive(:connection).with("000000000000000000000", "test@example.com")
        subject.invalidate(options, files)
      end

      it "should not raise errors" do
        subject.invalidate(options, files)
      end

      it "should call cloudflare to purge each file for each base url" do
        expect(double_cloudflare).to receive(:zone_file_purge).once.ordered.with("example.com", "http://example.com/index.html")
        expect(double_cloudflare).to receive(:zone_file_purge).once.ordered.with("example.com", "http://example.com/")
        expect(double_cloudflare).to receive(:zone_file_purge).once.ordered.with("example.com", "http://example.com/test/index.html")
        expect(double_cloudflare).to receive(:zone_file_purge).once.ordered.with("example.com", "http://example.com/test/image.png")
        expect(double_cloudflare).to receive(:zone_file_purge).once.ordered.with("example.com", "https://example.com/index.html")
        expect(double_cloudflare).to receive(:zone_file_purge).once.ordered.with("example.com", "https://example.com/")
        expect(double_cloudflare).to receive(:zone_file_purge).once.ordered.with("example.com", "https://example.com/test/index.html")
        expect(double_cloudflare).to receive(:zone_file_purge).once.ordered.with("example.com", "https://example.com/test/image.png")
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
        expect(::CloudFlare).to receive(:connection).with("111111111111111111111", "test-env@example.com")
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
