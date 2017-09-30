require 'spec_helper'
require 'lib/middleman-cdn/cdns/base_protocol'

describe Middleman::Cli::RackspaceCDN do
  it_behaves_like "BaseCDN"

  describe '.key' do
    it "should be 'rackspace'" do
      expect(described_class.key).to eq("rackspace")
    end
  end

  describe '.example_configuration_elements' do
    it "should contain these keys" do
      required_keys = [:username, :api_key, :region, :container, :notification_email]
      expect(described_class.example_configuration_elements.keys).to eq(required_keys)
    end
  end

  describe '#invalidate' do
    let(:double_rackspace) { double("RackspaceClient") }

    before do
      allow(double_rackspace).to receive(:invalidate)
      allow(Middleman::Cli::RackspaceClient).to receive(:new).and_return(double_rackspace)
    end

    let(:files) { [ "/index.html", "/", "/test/index.html", "/test/image.png" ] }

    let(:files_no_dirs) { files.reject { |file| file.end_with?("/") } }

    context "all options provided" do
      let(:options) do
        {
          username: "00000000000000000000",
          api_key: "11111111111111111111",
          region: "222222",
          container: "333333",
          notification_email: "test@example.com",
        }
      end

      it "should instantiate rackspace client with credentails" do
        expect(Middleman::Cli::RackspaceClient).to receive(:new).with("00000000000000000000", "11111111111111111111")
        subject.invalidate(options, files)
      end

      it "should not raise errors" do
        subject.invalidate(options, files)
      end

      it "should invalidate each files one at a time" do
        expect(double_rackspace).to receive(:invalidate).once.ordered.with("222222", "333333", "/index.html", notification_email: "test@example.com")
        expect(double_rackspace).to receive(:invalidate).once.ordered.with("222222", "333333", "/test/index.html", notification_email: "test@example.com")
        expect(double_rackspace).to receive(:invalidate).once.ordered.with("222222", "333333", "/test/image.png", notification_email: "test@example.com")
        expect(double_rackspace).to_not receive(:invalidate).with(anything, anything, "/", anything)
        subject.invalidate(options, files)
      end

      it "should output saying invalidating each file" do
        files_escaped = files_no_dirs.map { |file| Regexp.escape(file) }
        expect { subject.invalidate(options, files) }.to output(/#{files_escaped.join(".+")}/m).to_stdout
      end

      it "should output saying success checkmarks" do
        expect { subject.invalidate(options, files) }.to output(/✔/).to_stdout
      end

      context "and errors occurs when purging" do
        before do
          allow(double_rackspace).to receive(:invalidate).and_raise(StandardError)
        end

        it "should output saying error information" do
          expect { subject.invalidate(options, files) }.to output(/error: StandardError/).to_stdout
        end
      end
    end

    context "environment variables used for credentials" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("RACKSPACE_USERNAME").and_return("00000000000000000000")
        allow(ENV).to receive(:[]).with("RACKSPACE_API_KEY").and_return("11111111111111111111")
      end

      let(:options) do
        {
          region: "222222",
          container: "333333",
          notification_email: "test@example.com",
        }
      end

      it "should instantiate with environment variable credentails" do
        expect(Middleman::Cli::RackspaceClient).to receive(:new).with("00000000000000000000", "11111111111111111111")
        subject.invalidate(options, files)
      end

      it "should not raise errors" do
        subject.invalidate(options, files)
      end
    end

    context "if username not provided" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("RACKSPACE_USERNAME").and_return(nil)
      end

      let(:options) do
        {
          api_key: "11111111111111111111",
          region: "222222",
          container: "333333",
          notification_email: "test@example.com",
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key rackspace\[:username\] is missing\./).to_stdout
      end
    end

    context "if api key not provided" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("RACKSPACE_API_KEY").and_return(nil)
      end

      let(:options) do
        {
          username: "00000000000000000000",
          region: "222222",
          container: "333333",
          notification_email: "test@example.com",
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key rackspace\[:api_key\] is missing\./).to_stdout
      end
    end

    context "if region not provided" do
      let(:options) do
        {
          username: "00000000000000000000",
          api_key: "11111111111111111111",
          container: "333333",
          notification_email: "test@example.com",
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key rackspace\[:region\] is missing\./).to_stdout
      end
    end

    context "if container not provided" do
      let(:options) do
        {
          username: "00000000000000000000",
          api_key: "11111111111111111111",
          region: "222222",
          notification_email: "test@example.com",
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key rackspace\[:container\] is missing\./).to_stdout
      end
    end

    context "if notification email not provided" do
      let(:options) do
        {
          username: "00000000000000000000",
          api_key: "11111111111111111111",
          region: "222222",
          container: "333333"
        }
      end

      it "should not raise error" do
        expect { subject.invalidate(options, files) }.to_not raise_error
      end

      it "should invalidate each file with a nil notification email" do
        expect(double_rackspace).to receive(:invalidate).once.ordered.with("222222", "333333", "/index.html", notification_email: nil)
        expect(double_rackspace).to receive(:invalidate).once.ordered.with("222222", "333333", "/test/index.html", notification_email: nil)
        expect(double_rackspace).to receive(:invalidate).once.ordered.with("222222", "333333", "/test/image.png", notification_email: nil)
        expect(double_rackspace).to_not receive(:invalidate).with(anything, anything, "/", notification_email: nil)
        subject.invalidate(options, files)
      end
    end

  end
end
