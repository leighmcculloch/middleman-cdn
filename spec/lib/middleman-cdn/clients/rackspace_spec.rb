require 'spec_helper'
require 'lib/middleman-cdn/clients/rackspace_response_doubles.rb'

describe Middleman::Cli::RackspaceClient, :include_rackspace_response_doubles do

  describe '#invalidate', :vcr do

    let(:username) { "111111" }
    let(:api_key) { "000000" }
    let(:region) { "DFW" }
    let(:container) { "container" }
    let(:notification_email) { "test@example.com" }

    let(:subject) { described_class.new(username, api_key) }

    before do
      allow(HTTParty).to receive(:post).and_return(double_for_response_auth_success)
      allow(HTTParty).to receive(:delete).and_return(double_for_response_delete)
    end

    context "authentication" do
      context "valid credentials" do
        before do
          expect(HTTParty).to receive(:post).with("https://identity.api.rackspacecloud.com/v2.0/tokens", {
            :body => {
              "auth" => {
                "RAX-KSKEY:apiKeyCredentials" => {
                  "username" => username,
                  "apiKey" => api_key
                }
              }
            }.to_json,
            :headers => {
              "Content-Type" => "application/json"
            }
          }).once.and_return(double_for_response_auth_success)
        end

        it "should authenticate using the given credentials" do
          subject.invalidate(region, container, "/index.html")
        end

        it "should authenticate once only" do
          subject.invalidate(region, container, "/index.html")
          subject.invalidate(region, container, "/dir/index.html")
        end
      end

      context "invalid credentials" do
        it "should raise error" do
          expect(HTTParty).to receive(:post).and_return(double_for_response_auth_fail)
          expect{ subject.invalidate(region, container, "/index.html") }.to raise_error(RuntimeError)
        end

        it "should retry authentication when needed" do
          expect(HTTParty).to receive(:post).with("https://identity.api.rackspacecloud.com/v2.0/tokens", anything).once.and_return(double_for_response_auth_fail)
          expect(HTTParty).to receive(:post).with("https://identity.api.rackspacecloud.com/v2.0/tokens", anything).once.and_return(double_for_response_auth_success)
          subject.invalidate(region, container, "/index.html") rescue nil
          subject.invalidate(region, container, "/index.html")
        end
      end
    end

    context "successful invalidate (204)" do
      it "should not raise error" do
        expect{ subject.invalidate(region, container, "/index.html") }.to_not raise_error
      end

      context "with notification email" do
        it "should include notification email in invalidation request" do
          expect(HTTParty).to receive(:delete).with(anything, hash_including({
            :headers => hash_including({
              "x-purge-email" => "test@example.com"
            })
          })).once.and_return(double_for_response_delete)
          subject.invalidate(region, container, "/index.html", notification_email: "test@example.com")
        end
      end

      context "with file names that contain characters not allowed in a URL" do
        it "should escape the file path" do
          expect(HTTParty).to receive(:delete).with(match(/\/dir\/index%20file.html$/), anything).once.and_return(double_for_response_delete)
          subject.invalidate(region, container, "/dir/index file.html")
        end
      end
    end

    context "unsuccessful invalidation" do
      it "should raise error on 400 with fail message" do
        expect(HTTParty).to receive(:delete).and_return(double_for_response_delete(status_code: 400, fail_message: "the fail message"))
        expect{ subject.invalidate(region, container, "/index.html") }.to raise_error(RuntimeError, "400, the fail message")
      end

      it "should raise error on 400 without fail message" do
        expect(HTTParty).to receive(:delete).and_return(double_for_response_delete(status_code: 400))
        expect{ subject.invalidate(region, container, "/index.html") }.to raise_error(RuntimeError, "400, an error occurred.")
      end

      it "should raise error on 403" do
        expect(HTTParty).to receive(:delete).and_return(double_for_response_delete(status_code: 403))
        expect{ subject.invalidate(region, container, "/index.html") }.to raise_error(RuntimeError, "403, the server refused to respond to the request. Check your credentials.")
      end

      it "should raise error on 404" do
        expect(HTTParty).to receive(:delete).and_return(double_for_response_delete(status_code: 404))
        expect{ subject.invalidate(region, container, "/index.html") }.to raise_error(RuntimeError, "404, the requested resource could not be found.")
      end

      it "should raise error on any unspecified response codes" do
        expect(HTTParty).to receive(:delete).and_return(double_for_response_delete(status_code: 999))
        expect{ subject.invalidate(region, container, "/index.html") }.to raise_error(RuntimeError, "999, an error occurred.")
      end

      it "should raise error on any unspecified response codes with fail message in body" do
        expect(HTTParty).to receive(:delete).and_return(double_for_response_delete(status_code: 999, fail_message: "the error has arrived"))
        expect{ subject.invalidate(region, container, "/index.html") }.to raise_error(RuntimeError, "999, an error occurred. the error has arrived")
      end
    end

  end
end
