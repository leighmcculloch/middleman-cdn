require 'spec_helper'

describe Middleman::Cli::CDN do
  let(:subject) { described_class.new }

  describe '.exit_on_failure?' do
    it "should return true" do
      expect(described_class.exit_on_failure?).to eq(true)
    end
  end

  describe '.say_status' do
    context "defaults" do
      it "should say" do
        described_class.say_status(nil, "a status")
      end
    end

    context "with a cdn" do 
      it "should say" do
        described_class.say_status("the cdn", "a status")
      end
    end
  end

  describe '#cdn_invalidate' do
    before do
      allow(Dir).to receive(:chdir).with(anything) { |path, &block| block.call }
      allow(Dir).to receive(:glob).with('**/*', File::FNM_DOTMATCH).and_return([".", "index.html", "image.png", "blog/index.html"])
      allow(File).to receive(:directory?).with(".").and_return(true)
      allow(File).to receive(:directory?).with("blog/index.html").and_return(false)
      allow(File).to receive(:directory?).with("index.html").and_return(false)
      allow(File).to receive(:directory?).with("image.png").and_return(false)
    end

    context "all files matched" do
      context "no cdn provided" do
        let(:options) do
          OpenStruct.new({
            filter: /.*/
          })
        end

        it "should invalidate the files with only cloudflare" do
          expect_any_instance_of(::Middleman::Cli::CloudFlareCDN).to_not receive(:invalidate)
          expect_any_instance_of(::Middleman::Cli::CloudFrontCDN).to_not receive(:invalidate)
          expect_any_instance_of(::Middleman::Cli::FastlyCDN).to_not receive(:invalidate)
          expect { subject.cdn_invalidate(options) }.to raise_error(RuntimeError)
        end
      end

      context "one cdn provided" do
        let(:options) do
          OpenStruct.new({
            cloudflare: {},
            filter: /.*/
          })
        end

        it "should invalidate the files with only cloudflare" do
          expect_any_instance_of(::Middleman::Cli::CloudFlareCDN).to receive(:invalidate).with(options.cloudflare, ["/index.html", "/", "/image.png", "/blog/index.html", "/blog/", "/blog"], all: true)
          expect_any_instance_of(::Middleman::Cli::CloudFrontCDN).to_not receive(:invalidate)
          expect_any_instance_of(::Middleman::Cli::FastlyCDN).to_not receive(:invalidate)
          subject.cdn_invalidate(options)
        end
      end

      context "all cdns provided" do
        let(:options) do
          OpenStruct.new({
            cloudflare: {},
            cloudfront: {},
            fastly: {},
            filter: /.*/
          })
        end

        it "should invalidate the files with all cdns" do
          expect_any_instance_of(::Middleman::Cli::CloudFlareCDN).to receive(:invalidate).with(options.cloudflare, ["/index.html", "/", "/image.png", "/blog/index.html", "/blog/", "/blog"], all: true)
          expect_any_instance_of(::Middleman::Cli::CloudFrontCDN).to receive(:invalidate).with(options.cloudfront, ["/index.html", "/", "/image.png", "/blog/index.html", "/blog/", "/blog"], all: true)
          expect_any_instance_of(::Middleman::Cli::FastlyCDN).to receive(:invalidate).with(options.fastly, ["/index.html", "/",  "/image.png", "/blog/index.html", "/blog/", "/blog"], all: true)
          subject.cdn_invalidate(options)
        end
      end
    end

    context "some files matched" do
      let(:options) do
        OpenStruct.new({
          cloudflare: {},
          cloudfront: {},
          fastly: {},
          filter: /\.html/
        })
      end

      it "should invalidate the files with all cdns" do
        expect_any_instance_of(::Middleman::Cli::CloudFlareCDN).to receive(:invalidate).with(options.cloudflare, ["/index.html", "/", "/blog/index.html", "/blog/", "/blog"], all: false)
        expect_any_instance_of(::Middleman::Cli::CloudFrontCDN).to receive(:invalidate).with(options.cloudfront, ["/index.html", "/", "/blog/index.html", "/blog/", "/blog"], all: false)
        expect_any_instance_of(::Middleman::Cli::FastlyCDN).to receive(:invalidate).with(options.cloudfront, ["/index.html", "/", "/blog/index.html", "/blog/", "/blog"], all: false)
        subject.cdn_invalidate(options)
      end
    end

    context "no files matched" do
      let(:options) do
        OpenStruct.new({
          cloudflare: {},
          cloudfront: {},
          fastly: {},
          filter: /\.htm$/
        })
      end

      it "should invalidate the files with all cdns" do
        expect_any_instance_of(::Middleman::Cli::CloudFlareCDN).to_not receive(:invalidate)
        expect_any_instance_of(::Middleman::Cli::CloudFrontCDN).to_not receive(:invalidate)
        expect_any_instance_of(::Middleman::Cli::FastlyCDN).to_not receive(:invalidate)
        subject.cdn_invalidate(options)
      end
    end

    context "list of files provided at runtime" do
      context "invalidate files given and not the filter" do
        let(:options) do
          OpenStruct.new({
            cloudflare: {},
            cloudfront: {},
            fastly: {},
            filter: /\.htm$/
          })
        end

        it "should invalidate the files with all cdns" do
          expect_any_instance_of(::Middleman::Cli::CloudFlareCDN).to receive(:invalidate).with(options.cloudflare, ["/image.png"], all: false)
          expect_any_instance_of(::Middleman::Cli::CloudFrontCDN).to receive(:invalidate).with(options.cloudfront, ["/image.png"], all: false)
          expect_any_instance_of(::Middleman::Cli::FastlyCDN).to receive(:invalidate).with(options.cloudfront, ["/image.png"], all: false)
          subject.cdn_invalidate(options, "image.png")
        end
      end

      context "invalidate multiple files given and not the filter" do
        let(:options) do
          OpenStruct.new({
            cloudflare: {},
            cloudfront: {},
            fastly: {},
            filter: /\.htm$/
          })
        end

        it "should invalidate the files with all cdns" do
          expect_any_instance_of(::Middleman::Cli::CloudFlareCDN).to receive(:invalidate).with(options.cloudflare, ["/image.png", "/index.html", "/"], all: false)
          expect_any_instance_of(::Middleman::Cli::CloudFrontCDN).to receive(:invalidate).with(options.cloudfront, ["/image.png", "/index.html", "/"], all: false)
          expect_any_instance_of(::Middleman::Cli::FastlyCDN).to receive(:invalidate).with(options.cloudfront, ["/image.png", "/index.html", "/"], all: false)
          subject.cdn_invalidate(options, "image.png", "index.html")
        end
      end

      context "invalidate files and still expand index.html's to directories too" do
        let(:options) do
          OpenStruct.new({
            cloudflare: {},
            cloudfront: {},
            fastly: {},
            filter: /\.htm$/
          })
        end

        it "should invalidate the files with all cdns" do
          expect_any_instance_of(::Middleman::Cli::CloudFlareCDN).to receive(:invalidate).with(options.cloudflare, ["/index.html", "/"], all: false)
          expect_any_instance_of(::Middleman::Cli::CloudFrontCDN).to receive(:invalidate).with(options.cloudfront, ["/index.html", "/"], all: false)
          expect_any_instance_of(::Middleman::Cli::FastlyCDN).to receive(:invalidate).with(options.cloudfront, ["/index.html", "/"], all: false)
          subject.cdn_invalidate(options, "index.html")
        end
      end
    end
  end
end
