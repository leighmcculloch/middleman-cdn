require 'spec_helper'
require 'lib/middleman-cdn/cdns/base_protocol'

describe Middleman::Cli::FastlyCDN do
  it_behaves_like "BaseCDN"

  describe '.key' do
    it "should be 'fastly'" do
      expect(described_class.key).to eq("fastly")
    end
  end

  describe '.example_configuration_elements' do
    it "should contain these keys" do
      required_keys = [:api_key, :base_urls]
      expect(described_class.example_configuration_elements.keys).to eq(required_keys)
    end
  end

  describe '#invalidate' do
    let(:double_fastly) { double("::Fastly") }

    before do
      allow(double_fastly).to receive(:purge)
      allow(::Fastly).to receive(:new).and_return(double_fastly)
    end

    let(:files) { [ "/index.html", "/", "/test/index.html", "/test/image.png" ] }

    context "all options provided" do
      let(:options) do
        {
          api_key: '000000000000000000000',
          base_urls: ['http://www.example.com', 'https://www.example.com']
        }
      end

      it "should connect to fastly with credentails" do
        expect(::Fastly).to receive(:new).with({:api_key => "000000000000000000000"})
        subject.invalidate(options, files)
      end

      it "should not raise errors" do
        subject.invalidate(options, files)
      end

      it "should call cloudflare to purge each file for each base url" do
        expect(double_fastly).to receive(:purge).once.ordered.with("http://www.example.com/index.html")
        expect(double_fastly).to receive(:purge).once.ordered.with("http://www.example.com/")
        expect(double_fastly).to receive(:purge).once.ordered.with("http://www.example.com/test/index.html")
        expect(double_fastly).to receive(:purge).once.ordered.with("http://www.example.com/test/image.png")
        expect(double_fastly).to receive(:purge).once.ordered.with("https://www.example.com/index.html")
        expect(double_fastly).to receive(:purge).once.ordered.with("https://www.example.com/")
        expect(double_fastly).to receive(:purge).once.ordered.with("https://www.example.com/test/index.html")
        expect(double_fastly).to receive(:purge).once.ordered.with("https://www.example.com/test/image.png")
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
          allow(double_fastly).to receive(:purge).and_raise(StandardError)
        end

        it "should output saying error information" do
          expect { subject.invalidate(options, files) }.to output(/error: StandardError/).to_stdout
        end
      end
    end

    context "environment variables used for credentials" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("FASTLY_API_KEY").and_return("111111111111111111111")
      end

      let(:options) do
        {
          base_urls: ['http://www.example.com', 'https://www.example.com']
        }
      end

      it "should connect to fastly with environment variable credentails" do
        expect(::Fastly).to receive(:new).with({:api_key => "111111111111111111111"})
        subject.invalidate(options, files)
      end

      it "should not raise errors" do
        subject.invalidate(options, files)
      end
    end

    context "if client_api_key not provided" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("FASTLY_API_KEY").and_return(nil)
      end

      let(:options) do
        {
          base_urls: ['http://www.example.com', 'https://www.example.com']
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key fastly\[:api_key\] is missing\./).to_stdout
      end
    end

    context "if base_urls not provided" do
      let(:options) do
        {
          api_key: '000000000000000000000'
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key fastly\[:base_urls\] is missing\./).to_stdout
      end
    end

    context "if base_urls is a String" do
      let(:options) do
        {
          api_key: '000000000000000000000',
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
          api_key: '000000000000000000000',
          base_urls: []
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key fastly\[:base_urls\] is missing\./).to_stdout
      end
    end

    context "if base_urls is not an Array or String" do
      let(:options) do
        {
          api_key: '000000000000000000000',
          base_urls: 200
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key fastly\[:base_urls\] must be an array and contain at least one base url\./).to_stdout
      end
    end
  end
end
