require 'spec_helper'
require 'lib/middleman-cdn/cdns/base_protocol'

describe Middleman::Cli::MaxCDN do
  it_behaves_like "BaseCDN"

  describe '.key' do
    it "should be 'maxcdn'" do
      expect(described_class.key).to eq("maxcdn")
    end
  end

  describe '.example_configuration_elements' do
    it "should contain these keys" do
      required_keys = [:alias, :consumer_key, :consumer_secret, :zone_id]
      expect(described_class.example_configuration_elements.keys).to eq(required_keys)
    end
  end

  describe '#invalidate' do
    let(:double_maxcdn) { double("::MaxCDN::Client") }

    before do
      allow(double_maxcdn).to receive(:purge)
      allow(::MaxCDN::Client).to receive(:new).and_return(double_maxcdn)
    end

    let(:files) { [ "/index.html", "/", "/test/index.html", "/test/image.png" ] }

    context "all options provided" do
      let(:options) do
        {
          alias: "00000000000000000000",
          consumer_key: "11111111111111111111",
          consumer_secret: "22222222222222222222",
          zone_id: "33333333",
        }
      end

      it "should connect to maxcdn with credentails" do
        expect(::MaxCDN::Client).to receive(:new).with("00000000000000000000", "11111111111111111111", "22222222222222222222")
        subject.invalidate(options, files)
      end

      it "should not raise errors" do
        subject.invalidate(options, files)
      end

      it "should call cloudflare to purge all files in one hit" do
        expect(double_maxcdn).to receive(:purge).with("33333333", ["/index.html", "/", "/test/index.html", "/test/image.png"])
        subject.invalidate(options, files)
      end

      it "should output saying invalidating each file" do
        expect { subject.invalidate(options, files) }.to output(/Invalidating 4 files.../).to_stdout
      end

      it "should output saying success checkmarks" do
        expect { subject.invalidate(options, files) }.to output(/✔/).to_stdout
      end

      context "and errors occurs when purging" do
        before do
          allow(double_maxcdn).to receive(:purge).and_raise(StandardError)
        end

        it "should output saying error information" do
          expect { subject.invalidate(options, files) }.to output(/error: StandardError/).to_stdout
        end
      end
    end

    context "environment variables used for credentials" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("MAXCDN_ALIAS").and_return("00000000000000000000")
        allow(ENV).to receive(:[]).with("MAXCDN_CONSUMER_KEY").and_return("11111111111111111111")
        allow(ENV).to receive(:[]).with("MAXCDN_CONSUMER_SECRET").and_return("22222222222222222222")
      end

      let(:options) do
        {
          zone_id: "33333333",
        }
      end

      it "should connect to maxcdn with environment variable credentails" do
        expect(::MaxCDN::Client).to receive(:new).with("00000000000000000000", "11111111111111111111", "22222222222222222222")
        subject.invalidate(options, files)
      end

      it "should not raise errors" do
        subject.invalidate(options, files)
      end
    end

    context "if alias not provided" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("MAXCDN_ALIAS").and_return(nil)
      end

      let(:options) do
        {
          consumer_key: "11111111111111111111",
          consumer_secret: "22222222222222222222",
          zone_id: "33333333",
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key maxcdn\[:alias\] is missing\./).to_stdout
      end
    end

    context "if consumer_key not provided" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("MAXCDN_CONSUMER_KEY").and_return(nil)
      end

      let(:options) do
        {
          alias: "00000000000000000000",
          consumer_secret: "22222222222222222222",
          zone_id: "33333333",
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key maxcdn\[:consumer_key\] is missing\./).to_stdout
      end
    end

    context "if consumer_secret not provided" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("MAXCDN_CONSUMER_SECRET").and_return(nil)
      end

      let(:options) do
        {
          alias: "00000000000000000000",
          consumer_key: "11111111111111111111",
          zone_id: "33333333",
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key maxcdn\[:consumer_secret\] is missing\./).to_stdout
      end
    end

    context "if zone_id not provided" do
      let(:options) do
        {
          alias: "00000000000000000000",
          consumer_key: "11111111111111111111",
          consumer_secret: "22222222222222222222",
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key maxcdn\[:zone_id\] is missing\./).to_stdout
      end
    end
  end
end
